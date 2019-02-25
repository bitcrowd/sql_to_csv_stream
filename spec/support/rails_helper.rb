require_relative '../integration/dummy_app/config/environment.rb'

require 'capybara/rails'
require 'capybara/rspec'

Capybara.server = :puma # Until your setup is working
# Capybara.server = :puma, { Silent: true } # To clean up your test output
