module SqlToCsvStream
  module RailsSupport
    def self.register_renderer
      ActionController::Renderers.add :csv_from_sql do |sql, options|
        filename = options.fetch(:filename, 'data.csv')
        copy_options = options.fetch(:copy_options, {})
        headers_option = options.fetch(:headers, {})

        merged_headers = SqlToCsvStream::RailsSupport.default_headers(filename)
                                                     .merge(headers_option)
        merged_headers.each { |k, v| headers[k.to_s] = v.to_s }
        headers.delete('Content-Length') unless merged_headers['Content-Length']

        response.status = options.fetch(:status, 200)
        if request.headers['HTTP_ACCEPT_ENCODING'].to_s.include?('gzip')
          use_gzip = true
          headers['Content-Encoding'] = 'gzip'
        else
          use_gzip = false
        end

        self.response_body = Stream.new(sql, copy_options: copy_options, use_gzip: use_gzip)
      end
    end

    def self.default_headers(filename)
      {
        'Content-Type' => 'text/csv; charset=utf-8',
        'Content-Disposition' => "attachment; filename=\"#{filename}\"",
        # from nginx doc: Setting this to "no" will allow unbuffered responses suitable for Comet and HTTP streaming applications
        'X-Accel-Buffering' => 'no',
        'Cache-Control' => 'no-cache'
      }
    end
  end
end
