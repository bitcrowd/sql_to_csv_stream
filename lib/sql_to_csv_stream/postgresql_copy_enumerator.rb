# frozen_string_literal: true

module SqlToCsvStream
  class PostgresqlCopyEnumerator
    COPY_OPTIONS_DEFAULTS = {
      encoding: 'utf8'
    }.freeze

    def self.default_connection
      raise 'PostgreSQL database connection required' unless defined?(ActiveRecord)

      ActiveRecord::Base.connection.raw_connection
    end

    def initialize(sql, connection: self.class.default_connection, copy_options: {})
      @sql = sql.chomp(';')
      @connection = connection
      @copy_options = COPY_OPTIONS_DEFAULTS.merge(copy_options)
    end

    def each
      @connection.copy_data(copy_sql) do
        while (row = @connection.get_copy_data)
          yield(row) if block_given?
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
  end
end
