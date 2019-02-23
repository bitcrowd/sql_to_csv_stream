require 'sql_to_csv_stream/version'
require 'sql_to_csv_stream/csv_stream'
require 'sql_to_csv_stream/json_stream'
require 'sql_to_csv_stream/rails_support'

module SqlToCsvStream
  def self.register_csv_from_sql_rails_renderer
    RailsSupport.register_renderer
  end
end
