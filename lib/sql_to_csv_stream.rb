# frozen_string_literal: true

require 'sql_to_csv_stream/version'
require 'sql_to_csv_stream/gzip_wrapper'
require 'sql_to_csv_stream/csv_stream'
require 'sql_to_csv_stream/json_stream'
require 'sql_to_csv_stream/rails_support'

module SqlToCsvStream
  def self.register_rails_renderer
    RailsSupport.register_renderer
  end
end
