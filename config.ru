# frozen_string_literal: true

require 'bundler/setup'
require 'rack'
require_relative './app/ui'
require_relative './app/api'

# Route UI at root, and send API endpoints to the API app.
run Rack::URLMap.new(
	'/plan' => Foresight::API,
	'/strategies' => Foresight::API,
	'/' => Foresight::UI
)
