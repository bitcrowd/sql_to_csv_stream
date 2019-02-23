module SqlToCsvStream
  module RailsSupport
    def self.register_renderer
      ActionController::Renderers.add :csv_stream do |sql, options|
        stream_options = SqlToCsvStream::RailsSupport.prepare_streaming(
          'text/csv',
          request,
          response,
          headers,
          options
        )
        self.response_body = CsvStream.new(sql, **stream_options)
      end

      ActionController::Renderers.add :json_stream do |sql, options|
        stream_options = SqlToCsvStream::RailsSupport.prepare_streaming(
          'application/json',
          request,
          response,
          headers,
          options
        ).slice(:use_gzip)
        self.response_body = JsonStream.new(sql, **stream_options)
      end
    end

    def self.default_headers(filename, type)
      {
        'Content-Type' => "#{type}; charset=utf-8",
        'Content-Disposition' => "attachment; filename=\"#{filename}\"",
        # from nginx doc: Setting this to "no" will allow unbuffered responses suitable for Comet and HTTP streaming applications
        'X-Accel-Buffering' => 'no',
        'Cache-Control' => 'no-cache'
      }
    end

    def self.prepare_streaming(type, request, response, response_headers, options)
      filename = options.fetch(:filename, 'data')
      copy_options = options.fetch(:copy_options, {})
      headers_option = options.fetch(:headers, {})
      merged_headers = default_headers(filename, type).merge(headers_option)

      merged_headers.each { |k, v| response_headers[k.to_s] = v.to_s }
      response_headers.delete('Content-Length') unless merged_headers['Content-Length']
      response.status = options.fetch(:status, 200)

      if request.headers['HTTP_ACCEPT_ENCODING'].to_s.include?('gzip')
        response_headers['Content-Encoding'] = 'gzip'
        return { copy_options: copy_options, use_gzip: true }
      end

      return { copy_options: copy_options, use_gzip: false }
    end
  end
end
