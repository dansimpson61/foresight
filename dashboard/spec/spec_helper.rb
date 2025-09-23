require 'rack/test'
require 'rspec'
require 'capybara/rspec'
require 'capybara/cuprite'

require_relative '../dashboard'

ENV['RACK_ENV'] = 'test'

# Configure Capybara for feature specs
Capybara.app = Sinatra::Application
Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800])
end

# Configure Rack::Test for request specs
module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

# Conditionally include the correct modules based on spec type
RSpec.configure do |config|
  config.include RSpecMixin, type: :request
  config.include Capybara::DSL, type: :feature
end
