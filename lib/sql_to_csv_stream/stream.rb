module SqlToCsvStream
  class Stream
    COPY_OPTIONS_DEFAULTS = {
      format: 'CSV',
      header: true,
      # force_quote: '*',
      # escape: "E'\\\\'",
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

      @connection.copy_data "COPY (#{@sql}) TO STDOUT WITH (#{joined_copy_options})" do
        while row = @connection.get_copy_data
          if use_gzip?
            @gzip_writer.write(row)
          else
            write row
          end
        end
      end
    ensure
      @gzip_writer.close if use_gzip?
    end

    def write(string)
      return unless @stream
      @stream << string
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
