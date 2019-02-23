require 'sql_to_csv_stream/abstract_stream'

module SqlToCsvStream
  class JsonStream < AbstractStream
    COPY_OPTIONS_DEFAULTS = {
      format: 'TEXT',
      encoding: 'utf8'
    }.freeze

    private

    def execute_query_and_stream_data
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
    end

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
  end
end
