# frozen_string_literal: true

module SqlToCsvStream
  class CsvStream
    # Other possible options are
    #   force_quote: '*'
    #   escape: "E'\\\\'"
    # For details see Postgresqls COPY documentation.
    COPY_OPTIONS_DEFAULTS = {
      format: 'CSV',
      header: true
    }.freeze

    def initialize(object, connection: PostgresqlCopyEnumerator.default_connection, copy_options: {})
      sql = object.respond_to?(:to_sql) ? object.to_sql : object.to_s
      copy_options = COPY_OPTIONS_DEFAULTS.merge(copy_options)
      @copy_enum = PostgresqlCopyEnumerator.new(sql, connection: connection, copy_options: copy_options)
    end

    def each(&block)
      @copy_enum.each do |line|
        block.yield(line)
      end
    end
  end
end
