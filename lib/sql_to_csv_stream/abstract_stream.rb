# frozen_string_literal: true

module SqlToCsvStream
  class AbstractStream
    def initialize(object, connection: default_connection, use_gzip: false)
      @sql = (object.respond_to?(:to_sql) ? object.to_sql : object.to_s).chomp(';')
      @connection = connection
      @copy_options = self.class::COPY_OPTIONS_DEFAULTS
      @use_gzip = use_gzip
    end

    def each(&stream)
      # Zlib::GzipWriter needs to get passed an object that implements the #write method.
      # this is why we implement the #write method further down
      # while assigning the stream we need to write to in an instance variable to be used there.
      @gzip_writer = Zlib::GzipWriter.new(self) if use_gzip?
      @stream = stream

      execute_query_and_stream_data
    ensure
      @gzip_writer.close if use_gzip?
    end

    def write(string)
      return unless @stream
      @stream.yield(string)
    end

    private

    def execute_query_and_stream_data
      raise 'should be implemented in a subclass'
    end

    def zipped_write(string)
      if use_gzip?
        @gzip_writer.write(string)
      else
        write(string)
      end
    end

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
