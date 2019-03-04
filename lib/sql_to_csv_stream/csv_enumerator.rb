# frozen_string_literal: true

require 'csv'

module SqlToCsvStream
  class CsvEnumerator
    PREFIXES_TO_ESCAPE = %w[= @ + - |].freeze
    ESCAPE_CHAR = "'".freeze

    # Other possible options are
    #   force_quote: '*'
    #   escape: "E'\\\\'"
    # For details see Postgresqls COPY documentation.
    COPY_OPTIONS_DEFAULTS = {
      format: 'CSV',
      header: true
    }.freeze

    def initialize(
      object,
      connection: PostgresqlCopyEnumerator.default_connection,
      copy_options: {},
      sanitize: true,
      force_quotes: false
    )
      @sanitize = sanitize
      @force_quotes = force_quotes

      sql = (object.respond_to?(:to_sql) ? object.to_sql : object.to_s).chomp(';')
      copy_options = COPY_OPTIONS_DEFAULTS.merge(copy_options)
      copy_options[:force_quote] = '*' if @force_quotes
      @copy_enum = PostgresqlCopyEnumerator.new(sql, connection: connection, copy_options: copy_options)
    end

    def each
      @copy_enum.each do |line|
        yield(sanitize(line)) if block_given?
      end
    end

    private

    def sanitize(line)
      return line unless @sanitize

      row = CSV.parse_line(line, headers: false)
               .map do |value|
                 if value.to_s.start_with?(*PREFIXES_TO_ESCAPE)
                   ESCAPE_CHAR + value
                 else
                   value
                 end
               end

      CSV.generate_line(row, headers: false, force_quotes: @force_quotes)
    end
  end
end
