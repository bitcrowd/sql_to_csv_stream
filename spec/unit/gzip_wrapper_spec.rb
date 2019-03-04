# frozen_string_literal: true

RSpec.describe SqlToCsvStream::GzipWrapper do
  subject(:unzipped_output) { Zlib.gunzip(concatenated_output) }

  let(:concatenated_output) do
    String.new.tap do |output| # rubocop:disable Style/EmptyLiteral
      gzip_wrapper.each { |s| output << s }
    end
  end
  let(:gzip_wrapper) { described_class.new(source) }
  let(:source) { (1..10).to_a }

  it 'zips numbers from 1 to 10' do
    expect(unzipped_output).to eq((1..10).to_a.map(&:to_s).join)
  end

  context 'with an empty enumerator' do
    let(:source) { [] }

    it 'produces a zipped empty string' do
      expect(unzipped_output).to eq ''
    end
  end
end
