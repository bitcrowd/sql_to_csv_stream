# frozen_string_literal: true

require 'sql_to_csv_stream/version'
require 'sql_to_csv_stream/gzip_wrapper'
require 'sql_to_csv_stream/postgresql_copy_enumerator'
require 'sql_to_csv_stream/csv_enumerator'
require 'sql_to_csv_stream/json_enumerator'
require 'sql_to_csv_stream/rails_support'

module SqlToCsvStream
  def self.register_rails_renderer
    RailsSupport.register_renderer
  end
end
