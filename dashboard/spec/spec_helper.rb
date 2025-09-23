require 'rack/test'
require 'rspec'
require 'capybara/rspec'
require 'capybara/cuprite'

require_relative '../dashboard'

ENV['RACK_ENV'] = 'test'

Capybara.app = Sinatra::Application
Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800])
end

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.include Capybara::DSL
end
