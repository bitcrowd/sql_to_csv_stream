# frozen_string_literal: true

module SqlToCsvStream
  class JsonStream
    COPY_OPTIONS_DEFAULTS = {
      format: 'TEXT',
      encoding: 'utf8'
    }.freeze

    def initialize(object, connection: default_connection)
      @sql = (object.respond_to?(:to_sql) ? object.to_sql : object.to_s).chomp(';')
      @connection = connection
      @copy_options = COPY_OPTIONS_DEFAULTS
    end

    def each(&stream)
      first_line = true
      @connection.copy_data copy_sql do
        while (line = @connection.get_copy_data)
          line = if first_line
                   '[' + line.chomp
                 else
                   ',' + line.chomp
                 end
          stream.yield(line)
          first_line = false
        end
      end
      stream.yield('[') if first_line
      stream.yield("]\n")
    end

    private

    # The source/author of this magic is:
    # https://dba.stackexchange.com/questions/90482/export-postgres-table-as-json?newreg=0b667caa47c34084bee6c90feec5e4be
    #
    # The idea is to stream with postgresql COPY command with the TEXT format.
    # To do this, we need to convert each row in the postgresql query result into JSON first.
    # This query does exactly that by using ROW_TO_JSON.
    # There is one edge case when text in that JSON contains backslashes -- to not break our
    # escaping, we need to manually add additional escape-backslashes.
    def copy_sql
      "COPY (
        SELECT REGEXP_REPLACE(ROW_TO_JSON(t)::TEXT, '\\\\', '\\', 'g')
        FROM (#{@sql}) AS t
      ) TO STDOUT WITH (#{joined_copy_options});"
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
