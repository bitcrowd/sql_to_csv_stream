# frozen_string_literal: true

require 'zlib'

module SqlToCsvStream
  class GzipWrapper
    def initialize(source)
      @source = source
    end

    def each(&block)
      @destination = block
      # Zlib::GzipWriter needs to get passed an object that implements the #write method.
      # this is why we implement the #write method further down
      # while assigning the stream we need to write to in an instance variable to be used there.
      @zipper = Zlib::GzipWriter.new(self)
      @source.each do |string|
        @zipper.write(string)
      end
    ensure
      @zipper.close
    end

    # called indirectly by Zlib::GzipWriter
    def write(zipped_string)
      @destination.yield(zipped_string)
    end
  end
end
