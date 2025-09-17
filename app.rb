#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'logger'
require_relative './foresight'
require_relative './app/api'
require_relative './app/ui'

set :protection, except: :frame_options
set :logging, true
set :logger, Logger.new(STDOUT)

use Foresight::API
use Foresight::UI
