# frozen_string_literal: true

require 'bundler/setup'
require_relative './app'

# Use the classic Sinatra application instance defined in app.rb
run Sinatra::Application
