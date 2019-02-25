# frozen_string_literal: true

require 'support/rails_helper'

RSpec.describe 'CSV Stream', type: :feature do
  let(:header) { "name,settings,accepted_terms\n" }
  let(:response) { page.body }

  before { User.delete_all }

  context 'when there is no user' do
    it 'returns only the CSV header with no content' do
      visit 'users.csv'
      expect(response).to eq header
    end

    context 'with compression enabled' do
      let(:response) { Zlib.gunzip(page.body) }

      before do
        page.driver.header('ACCEPT_ENCODING', 'gzip,*')
      end

      it 'responds with compressed header' do
        visit 'users.csv'
        expect(response).to eq header
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
    let(:serialized_users) do
      [
        header,
        "bit,\"{\"\"newsletter\"\":true}\",t\n",
        "crowd,\"{\"\"newsletter\"\":false,\"\"nested\"\":{\"\"values\"\":\"\"are possible\"\"}}\",f\n"
      ].join
    end

    before { users.map(&:save!) }

    it 'serializes all users with a CSV header' do
      visit 'users.csv'
      expect(response).to eq serialized_users
    end

    context 'with compression enabled' do
      let(:response) { Zlib.gunzip(page.body) }

      before do
        page.driver.header('ACCEPT_ENCODING', 'gzip,*')
      end

      it 'responds with compressed text' do
        visit 'users.csv'
        expect(response).to eq serialized_users
      end
    end
  end
end
