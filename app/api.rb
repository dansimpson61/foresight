# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative '../foresight'

module Foresight
  class API < Sinatra::Base
    helpers do
      def json_params
        request.body.rewind
        raw = request.body.read
        return {} if raw.nil? || raw.strip.empty?
        JSON.parse(raw, symbolize_names: true)
      rescue JSON::ParserError
        halt 400, { error: 'Invalid JSON' }.to_json
      end
    end

    get '/' do
      content_type :json
      { status: 'ok', service: 'foresight', version: Foresight::PlanService::SCHEMA_VERSION }.to_json
    end

    get '/strategies' do
      content_type :json
      svc = Foresight::PlanService.new
      { strategies: svc.list_strategies }.to_json
    end

    post '/plan' do
      content_type :json
      params = json_params
      begin
        result = Foresight::PlanService.run(params)
        result.to_json
      rescue => e
        halt 500, { error: e.message }.to_json
      end
    end

    get '/plan/example' do
      content_type :json
      example = {
        members: [
          { name: 'Alice', date_of_birth: '1961-06-15' },
          { name: 'Bob',   date_of_birth: '1967-02-10' }
        ],
        accounts: [
          { type: 'TraditionalIRA', owner: 'Alice', balance: 100_000.0 },
          { type: 'RothIRA', owner: 'Alice', balance: 50_000.0 },
          { type: 'TaxableBrokerage', owners: ['Alice','Bob'], balance: 20_000.0, cost_basis_fraction: 0.7 }
        ],
        income_sources: [
          { type: 'SocialSecurityBenefit', recipient: 'Alice', start_year: 2025, pia_annual: 24_000.0, cola_rate: 0.0 },
          { type: 'SocialSecurityBenefit', recipient: 'Bob',   start_year: 2030, pia_annual: 24_000.0, cola_rate: 0.0 }
        ],
        annual_expenses: 60_000.0,
        emergency_fund_floor: 20_000.0,
        desired_tax_bracket_ceiling: 94_300.0,
        start_year: 2025,
        years: 5,
        inflation_rate: 0.02,
        growth_assumptions: { traditional_ira: 0.02, roth_ira: 0.03, taxable: 0.01 },
        strategies: [ { key: 'do_nothing' }, { key: 'fill_to_top_of_bracket' } ]
      }
      JSON.pretty_generate(example)
    end
  end
end
