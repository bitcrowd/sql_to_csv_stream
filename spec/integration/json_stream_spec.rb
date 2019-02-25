# frozen_string_literal: true

require 'support/rails_helper'

RSpec.describe 'JSON Stream', type: :feature do
  let(:response) { page.body }

  before { User.delete_all }

  context 'when there is no user' do
    it 'returns only square brackets' do
      visit 'users.json'
      expect(response).to eq "[]\n"
    end

    context 'with compression enabled' do
      let(:response) { Zlib.gunzip(page.body) }

      before do
        page.driver.header('ACCEPT_ENCODING', 'gzip,*')
      end

      it 'responds with compressed square brackets' do
        visit 'users.json'
        expect(response).to eq "[]\n"
      end
    end
  end

  context 'with users in the database' do
    let(:user1) do
      User.new name: 'bit',
               settings: { newsletter: true },
               accepted_terms: true
    end
    let(:user2) do
      User.new name: 'crowd',
               settings: { newsletter: false, nested: { values: 'are possible' } },
               accepted_terms: false
    end
    let(:users) { [user1, user2] }

    before { users.map(&:save!) }

    it 'serializes all users' do
      visit 'users.json'
      expect(response).to eq [
        '[',
        '{"name":"bit","settings":{"newsletter":true},"accepted_terms":true},',
        '{"name":"crowd","settings":{"newsletter":false,"nested":{"values":"are possible"}},"accepted_terms":false}',
        "]\n"
      ].join
    end
  end
end
