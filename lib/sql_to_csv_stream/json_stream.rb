module SqlToCsvStream
  class JsonStream
    COPY_OPTIONS_DEFAULTS = {
      format: 'TEXT',
      encoding: 'utf8'
    }.freeze

    def initialize(sql, connection: default_connection, copy_options: {}, use_gzip: false)
      @sql = (sql.respond_to?(:to_sql) ? sql.to_sql : sql.to_s).chomp(';')
      @connection = connection
      @copy_options = COPY_OPTIONS_DEFAULTS.merge(copy_options)
      @use_gzip = use_gzip
    end

    def each(&stream)
      # GzipWriter needs to get passed an object that implements the #write method.
      # this is why we implement the #write method further down
      # while assigning the stream we need to write to in an instance variable to be used there.
      @gzip_writer = Zlib::GzipWriter.new(self) if use_gzip?
      @stream = stream

      copy_sql = "COPY (
        SELECT REGEXP_REPLACE(ROW_TO_JSON(t)::TEXT, '\\\\', '\\', 'g')
        FROM (#{@sql}) AS t
      ) TO STDOUT WITH (#{joined_copy_options});"

      first_line = true
      @connection.copy_data copy_sql do
        while line = @connection.get_copy_data
          if first_line
            line = '[' + line.chomp
          else
            line = ',' + line.chomp
          end
          zipped_write(line)
          first_line = false
        end
      end
      zipped_write("]\n")
    ensure
      @gzip_writer.close if use_gzip?
    end

    def zipped_write(string)
      if use_gzip?
        @gzip_writer.write(string)
      else
        write(string)
      end
    end

    def write(string)
      return unless @stream
      @stream.yield(string)
    end

    private

    def default_connection
      raise 'SqlToCsvStream::Stream needs a PostgreSQL database connection.' unless defined?(ActiveRecord)

      ActiveRecord::Base.connection.raw_connection
    end

    def joined_copy_options
      @copy_options.map { |k, v| "#{k.upcase} #{v}" }
                   .join(', ')
    end

    def use_gzip?
      @use_gzip
    end
  end
end
