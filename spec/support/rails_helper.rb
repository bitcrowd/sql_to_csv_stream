# frozen_string_literal: true

require_relative '../integration/dummy_app/config/environment.rb'

require 'capybara/rails'
require 'capybara/rspec'

ActiveRecord::Migration.maintain_test_schema!

Capybara.server = :puma # Until your setup is working
# Capybara.server = :puma, { Silent: true } # To clean up your test output
