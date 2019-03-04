# frozen_string_literal: true

module SqlToCsvStream
  module RailsSupport
    def self.register_renderer
      register_csv_renderer
      register_json_renderer
    end

    # `stream` can be anything that responds to `.each`.
    # We make use of this by providing our own stream that fetches data from Postgresql
    # stream = (1..10).lazy.map do |i|
    #   sleep(1);
    #   "#{i}\n";
    # end
    # stream = Enumerator.new do |strean|
    #   csv_service.call do |csv_line|
    #     strean << csv_line
    #   end
    # end
    def self.register_csv_renderer
      ActionController::Renderers.add :csv_stream do |sql, copy_options: {}, **options|
        sanitize = options.delete(:sanitize) || true
        force_quotes = options.delete(:force_quotes) || false
        filename = options.delete(:filename) || 'data.csv'
        stream = CsvEnumerator.new(sql, copy_options: copy_options, sanitize: sanitize, force_quotes: force_quotes)
        stream = GzipWrapper.new(stream) if RailsSupport.use_gzip?(request)
        RailsSupport.set_streaming_headers(headers, request, response, filename)
        stream
      end
    end

    def self.register_json_renderer
      ActionController::Renderers.add :json_stream do |sql, filename: 'data.csv'|
        stream = JsonEnumerator.new(sql)
        stream = GzipWrapper.new(stream) if RailsSupport.use_gzip?(request)
        RailsSupport.set_streaming_headers(headers, request, response, filename)
        stream
      end
    end

    def self.set_streaming_headers(headers, request, response, filename)
      headers['X-Accel-Buffering'] = 'no'
      headers['Cache-Control'] = 'no-cache'
      headers['Content-Encoding'] = 'gzip' if use_gzip?(request)
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers.delete('Content-Length')
      response.status = 200
    end

    def self.use_gzip?(request)
      request.headers['HTTP_ACCEPT_ENCODING']
             .to_s
             .include?('gzip')
    end
  end
end
