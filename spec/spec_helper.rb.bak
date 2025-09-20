# frozen_string_literal: true

require 'rack/test'
require 'rspec'

# Set the environment to 'test'
ENV['RACK_ENV'] = 'test'

# Pull in the main application file
require_relative '../app'

# This module will be included in our feature specs
module RSpecMixin
  include Rack::Test::Methods
  def app
    # This defines the app that Rack::Test will use
    Sinatra::Application
  end
end

RSpec.configure do |config|
  # Mixin the RSpecMixin for all feature specs
  config.include RSpecMixin, type: :feature

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
