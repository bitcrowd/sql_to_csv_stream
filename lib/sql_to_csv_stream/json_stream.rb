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

    def copy_sql
      "COPY (
        SELECT REGEXP_REPLACE(ROW_TO_JSON(t)::TEXT, '\\\\', '\\', 'g')
        FROM (#{@sql}) AS t
      ) TO STDOUT WITH (#{joined_copy_options});"
    end
  end
end
