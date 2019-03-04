# frozen_string_literal: true

RSpec.describe SqlToCsvStream::JsonEnumerator do
  describe '#each' do
    let(:enumerator) { described_class.new(sql, connection: stub_connection) }
    let(:stub_connection) { double }
    let(:sql) { 'SELECT * FROM users' }
    let(:expected_copy_sql) do
      'COPY (' \
        "SELECT REGEXP_REPLACE(ROW_TO_JSON(t)::TEXT, '\\\\', '\\', 'g') " \
        'FROM (SELECT * FROM users) AS t' \
        ') TO STDOUT WITH (ENCODING utf8, FORMAT TEXT)'
    end
    let(:postgresql_chunks) { [nil] }

    before do
      allow(stub_connection).to receive(:copy_data) { |&proc| proc.yield }
      allow(stub_connection).to receive(:get_copy_data).and_return(*postgresql_chunks)
    end

    it 'executes COPY with the given SQL with fake postgresql returning no results' do
      expect(stub_connection).to receive(:copy_data).with(expected_copy_sql)
      results = []
      enumerator.each { |chunk| results << chunk }
      expect(results.join).to eq "[]\n"
    end

    context 'when the given sql has a pending semicolon' do
      let(:sql) { 'SELECT * FROM users;' }

      it 'executes COPY with the given SQL' do
        expect(stub_connection).to receive(:copy_data).with(expected_copy_sql)
        enumerator.each { |_chunk| }
      end
    end

    context 'with postgresql returning data' do
      let(:postgresql_chunks) { ['first', 'second', nil] }

      it 'yields the data as given from the database connection' do
        results = []
        enumerator.each { |chunk| results << chunk }
        expect(results.join).to eq "[first,second]\n"
      end
    end
  end
end
