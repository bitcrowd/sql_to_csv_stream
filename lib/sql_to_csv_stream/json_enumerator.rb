# frozen_string_literal: true

module SqlToCsvStream
  class JsonEnumerator
    JSON_COPY_OPTIONS = { format: 'TEXT' }.freeze

    def initialize(object, connection: PostgresqlCopyEnumerator.default_connection)
      sql = object.respond_to?(:to_sql) ? object.to_sql : object.to_s
      # The inspiration of this magic was:
      # https://dba.stackexchange.com/questions/90482/export-postgres-table-as-json?newreg=0b667caa47c34084bee6c90feec5e4be
      #
      # The idea is to stream with postgresql COPY command with the TEXT format.
      # To do this, we need to convert each row in the postgresql query result into JSON first.
      # This query does exactly that by using ROW_TO_JSON.
      # There is one edge case when text in that JSON contains backslashes -- to not break our
      # escaping, we need to manually add additional escape-backslashes.
      sql = "SELECT REGEXP_REPLACE(ROW_TO_JSON(t)::TEXT, '\\\\', '\\', 'g') FROM (#{sql}) AS t"
      @copy_enum = PostgresqlCopyEnumerator.new(sql, connection: connection, copy_options: JSON_COPY_OPTIONS)
    end

    def each(&stream)
      first_line = true
      @copy_enum.each do |line|
        line = if first_line
                 '[' + line.chomp
               else
                 ',' + line.chomp
               end
        stream.yield(line)
        first_line = false
      end
      stream.yield('[') if first_line
      stream.yield("]\n")
    end
  end
end
