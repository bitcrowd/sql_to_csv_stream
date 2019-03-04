# frozen_string_literal: true

RSpec.describe SqlToCsvStream::PostgresqlCopyEnumerator do
  describe '.default_connection' do
    before { hide_const 'ActiveRecord' }

    it 'raises when ActiveRecord is not loaded' do
      expect {
        described_class.default_connection
      }.to raise_error(RuntimeError)
    end

    context 'with loaded ActiveRecord' do
      let(:activeRecordBaseStub) { Module.new }
      let(:stub_connection) { double }

      before do
        stub_const('ActiveRecord::Base', activeRecordBaseStub)
        expect(activeRecordBaseStub).to receive(:connection).and_return(stub_connection)
      end

      it 'returns the raw connection from active record base' do
        expect(stub_connection).to receive(:raw_connection).and_return('psql connection')
        expect(described_class.default_connection).to eq 'psql connection'
      end
    end
  end

  describe '#each' do
    let(:enumerator) { described_class.new(sql, connection: stub_connection) }
    let(:stub_connection) { double }
    let(:sql) { 'SELECT * FROM users' }
    let(:expected_copy_sql) { 'COPY (SELECT * FROM users) TO STDOUT WITH (ENCODING utf8)' }
    let(:postgresql_chunks) { [nil] }

    before do
      allow(stub_connection).to receive(:copy_data) { |&proc| proc.yield }
      allow(stub_connection).to receive(:get_copy_data).and_return(*postgresql_chunks)
    end

    it 'executes COPY with the given SQL' do
      expect(stub_connection).to receive(:copy_data).with(expected_copy_sql)
      enumerator.each { |_chunk| }
    end

    context 'when the given sql has a pending semicolon' do
      let(:sql) { 'SELECT * FROM users;' }

      it 'executes COPY with the given SQL' do
        expect(stub_connection).to receive(:copy_data).with(expected_copy_sql)
        enumerator.each { |_chunk| }
      end
    end

    context 'when given additional formatting options' do
      let(:enumerator) { described_class.new(sql, connection: stub_connection, copy_options: copy_options) }
      let(:copy_options) { { format: :csv, headers: true, encoding: 'utf32' } }
      let(:expected_copy_sql) { 'COPY (SELECT * FROM users) TO STDOUT WITH (ENCODING utf32, FORMAT csv, HEADERS true)' }

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
        expect(results).to match_array(%w[first second])
      end
    end
  end
end
