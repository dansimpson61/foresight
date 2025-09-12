# frozen_string_literal: true
require 'rspec'
require 'capybara/rspec'
require 'rack/test'
require 'selenium-webdriver'
require_relative '../app'

Capybara.app = Sinatra::Application
Capybara.server = :puma, { Silent: true }

# Headless Chrome driver for JS-enabled tests
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1200,900')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :headless_chrome

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Rack::Test::Methods, type: :request

  def app
    Sinatra::Application
  end
end
