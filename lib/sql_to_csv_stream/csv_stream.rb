require 'sql_to_csv_stream/abstract_stream'

module SqlToCsvStream
  class CsvStream < AbstractStream
    COPY_OPTIONS_DEFAULTS = {
      format: 'CSV',
      header: true,
      # force_quote: '*',
      # escape: "E'\\\\'",
      encoding: 'utf8'
    }.freeze

    def initialize(object, connection: default_connection, copy_options: {}, use_gzip: false)
      super(object, connection: connection, use_gzip: use_gzip)
      @copy_options = COPY_OPTIONS_DEFAULTS.merge(copy_options)
    end

    private

    def execute_query_and_stream_data
      @connection.copy_data copy_sql do
        while row = @connection.get_copy_data
          zipped_write(row)
        end
      end
    end

    def copy_sql
      "COPY (#{@sql}) TO STDOUT WITH (#{joined_copy_options})"
    end
  end
end
