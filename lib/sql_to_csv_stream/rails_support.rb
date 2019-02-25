# frozen_string_literal: true

module SqlToCsvStream
  module RailsSupport
    def self.register_renderer
      register_csv_renderer
      register_json_renderer
    end

    def self.register_csv_renderer
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
    end

    def self.register_json_renderer
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
        # from nginx doc: Setting this to "no" will allow unbuffered responses
        # suitable for HTTP streaming applications.
        'X-Accel-Buffering' => 'no',
        'Cache-Control' => 'no-cache'
      }
    end

    def self.prepare_streaming(type, request, response, response_headers, options)
      copy_options = options.fetch(:copy_options, {})
      apply_headers(options, type, response_headers)
      response.status = options.fetch(:status, 200)

      if request.headers['HTTP_ACCEPT_ENCODING'].to_s.include?('gzip')
        response_headers['Content-Encoding'] = 'gzip'
        return { copy_options: copy_options, use_gzip: true }
      end

      { copy_options: copy_options, use_gzip: false }
    end

    def self.apply_headers(options, type, response_headers)
      filename = options.fetch(:filename, 'data')
      user_defined_headers = options.fetch(:headers, {})

      merged_headers = default_headers(filename, type).merge(user_defined_headers)
      merged_headers.each do |header_name, header_value|
        response_headers[header_name.to_s] = header_value.to_s
      end
      response_headers.delete('Content-Length') unless merged_headers['Content-Length']
    end
  end
end
