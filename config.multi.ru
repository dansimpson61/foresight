# Unified Rack configuration to run both the main Foresight app and the Simple app in one server
# Usage: rackup config.multi.ru --port 9292

require_relative './app'
require_relative './simple/app'
require 'rack'

# Mount paths:
# - Main UI at /
# - API at /api (already mounted within app.rb via `use Foresight::API`)
# - Simple UI at /simple

map '/' do
  # Sinatra::Application is configured in app.rb to use Foresight::UI and Foresight::API
  run Sinatra::Application
end

map '/simple' do
  run Foresight::Simple::UI
end
