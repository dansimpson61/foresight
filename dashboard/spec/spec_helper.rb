require 'rspec'
require 'capybara/rspec'
require 'capybara/cuprite'

require_relative '../dashboard.rb'

ENV['RACK_ENV'] = 'test'

Capybara.app = Sinatra::Application
Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800])
end

RSpec.configure do |config|
  config.include Capybara::DSL, type: :feature
end
