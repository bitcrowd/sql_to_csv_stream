# frozen_string_literal: true

RSpec.describe SqlToCsvStream do
  it 'has a version number' do
    expect(SqlToCsvStream::VERSION).not_to be nil
  end

  it 'forwards register_rails_renderer to the RailsSupport module' do
    expect(SqlToCsvStream::RailsSupport).to receive(:register_renderer)
    SqlToCsvStream.register_rails_renderer
  end
end
