require 'action_controller'

RSpec.describe SqlToCsvStream::RailsSupport do
  describe '.register_renderer' do
    it 'registers our two rails renderers' do
      expect(ActionController::Renderers).to receive(:add).with(:csv_stream).once
      expect(ActionController::Renderers).to receive(:add).with(:json_stream).once

      SqlToCsvStream::RailsSupport.register_renderer
    end
  end
end
