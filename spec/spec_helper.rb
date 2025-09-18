# frozen_string_literal: true
require 'rspec'
require 'capybara/rspec'
require 'rack/test'
require 'selenium-webdriver'
require_relative '../app'

# New headless chrome options
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.app = Sinatra::Application
Capybara.server = :puma, { Silent: true }
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_driver = :selenium_chrome_headless

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Rack::Test::Methods, type: :request

  def app
    Sinatra::Application
  end
end
