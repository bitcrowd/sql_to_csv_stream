# frozen_string_literal: true

module SqlToCsvStream
  class CsvStream
    COPY_OPTIONS_DEFAULTS = {
      format: 'CSV',
      header: true,
      # force_quote: '*',
      # escape: "E'\\\\'",
      encoding: 'utf8'
    }.freeze

    def initialize(object, connection: default_connection, copy_options: {})
      @sql = (object.respond_to?(:to_sql) ? object.to_sql : object.to_s).chomp(';')
      @connection = connection
      @copy_options = COPY_OPTIONS_DEFAULTS.merge(copy_options)
    end

    def each(&stream)
      @connection.copy_data copy_sql do
        while (row = @connection.get_copy_data)
          stream.yield(row)
        end
      end
    end

    private

    def copy_sql
      "COPY (#{@sql}) TO STDOUT WITH (#{joined_copy_options})"
    end

    def joined_copy_options
      @copy_options.map { |k, v| "#{k.upcase} #{v}" }
                   .join(', ')
    end

    def default_connection
      raise 'SqlToCsvStream::Stream needs a PostgreSQL database connection.' unless defined?(ActiveRecord)

      ActiveRecord::Base.connection.raw_connection
    end
  end
end
