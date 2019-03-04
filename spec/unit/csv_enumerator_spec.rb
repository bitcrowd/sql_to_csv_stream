# frozen_string_literal: true

RSpec.describe SqlToCsvStream::CsvEnumerator do
  describe '#each' do
    let(:enumerator) { described_class.new(sql, connection: stub_connection) }
    let(:stub_connection) { double }
    let(:sql) { 'SELECT * FROM users' }
    let(:expected_copy_sql) { 'COPY (SELECT * FROM users) TO STDOUT WITH (ENCODING utf8, FORMAT CSV, HEADER true)' }
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
      let(:copy_options) { { header: false, encoding: 'utf32' } }
      let(:expected_copy_sql) { 'COPY (SELECT * FROM users) TO STDOUT WITH (ENCODING utf32, FORMAT CSV, HEADER false)' }

      it 'executes COPY with the given SQL' do
        expect(stub_connection).to receive(:copy_data).with(expected_copy_sql)
        enumerator.each { |_chunk| }
      end
    end

    context 'with postgresql returning data' do
      let(:postgresql_chunks) { ["fi,rs,t\n", "se,co,nd\n", nil] }

      it 'yields the data as given from the database connection' do
        results = []
        enumerator.each { |chunk| results << chunk }
        expect(results).to match_array(["fi,rs,t\n", "se,co,nd\n"])
      end

      context 'when a cell contains an excel-injection attack' do
        let(:postgresql_chunks) { ["=2+5|'/C calc'!A0\n", nil] }

        it 'escapes the special symbol' do
          results = []
          enumerator.each { |chunk| results << chunk }
          expect(results).to contain_exactly("'=2+5|'/C calc'!A0\n")
        end

        context 'when manually setting sanitize to false' do
          let(:enumerator) { described_class.new(sql, connection: stub_connection, sanitize: false) }

          it 'does not escape the special symbol' do
            results = []
            enumerator.each { |chunk| results << chunk }
            expect(results).to contain_exactly("=2+5|'/C calc'!A0\n")
          end
        end
      end

      context 'when setting force_quotes' do
        let(:enumerator) { described_class.new(sql, connection: stub_connection, force_quotes: true) }
        let(:postgresql_chunks) { ["=2+5|'/C calc'!A0\n", nil] }

        it 'yields the data as given from the database connection' do
          results = []
          enumerator.each { |chunk| results << chunk }
          expect(results).to match_array(["\"'=2+5|'/C calc'!A0\"\n"])
        end
      end
    end
  end
end
