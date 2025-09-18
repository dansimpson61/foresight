# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative '../foresight'
require_relative '../models/contract_validator'

module Foresight
  class API < Sinatra::Base
    helpers do
      def json_params
        request.body.rewind
        raw = request.body.read
        return {} if raw.nil? || raw.strip.empty?
        JSON.parse(raw, symbolize_names: true)
      rescue JSON::ParserError
        halt 400, { 
          status: 'error', 
          communication_step: 'Request Parsing',
          message: 'The request body could not be parsed as JSON.' 
        }.to_json
      end

      def wrap_response(payload)
        {
          metadata: {
            sender: 'Foresight::API',
            intended_receiver: 'Foresight::UI',
            timestamp: Time.now.iso8601
          },
          payload: payload
        }.to_json
      end
    end

    get '/' do
      content_type :json
      wrap_response({ status: 'ok', service: 'foresight', version: Foresight::PlanService::SCHEMA_VERSION })
    end

    get '/strategies' do
      content_type :json
      svc = Foresight::PlanService.new
      wrap_response({ strategies: svc.list_strategies })
    end

    post '/plan' do
      content_type :json
      
      request_data = json_params
      params = request_data[:payload]

      unless params
        halt 400, wrap_response({
          status: 'error',
          communication_step: 'Request Parsing',
          message: "The request is missing the 'payload' key."
        })
      end

      request_validation = Foresight::ContractValidator.validate_request(params)
      unless request_validation[:valid]
        halt 400, wrap_response({ 
          status: 'error',
          communication_step: 'Request (Frontend -> Backend)',
          message: Foresight::ContractValidator.generate_error_message(request_validation[:errors], params),
          details: request_validation[:errors] 
        })
      end

      begin
        result_hash = Foresight::PlanService.run(params)

        response_validation = Foresight::ContractValidator.validate_response(result_hash)
        unless response_validation[:valid]
          error_message = Foresight::ContractValidator.generate_error_message(response_validation[:errors], result_hash)
          logger.error "FATAL: PlanService broke the data contract. #{error_message}"
          halt 500, wrap_response({ 
            status: 'error', 
            communication_step: 'Response (Backend -> Frontend)',
            message: "The server generated invalid data. This is a server-side bug. #{error_message}",
            details: response_validation[:errors]
          })
        end

        wrap_response(result_hash)
      rescue => e
        logger.error "PlanService execution error: #{e.message}\n#{e.backtrace.join("\n")}"
        halt 500, wrap_response({ 
          status: 'error',
          communication_step: 'Simulation Engine',
          message: "An unexpected error occurred in the simulation: #{e.message}"
        })
      end
    end

    get '/plan/example' do
      content_type :json
      example = {
        members: [
          { name: 'Alice', date_of_birth: '1961-06-15' },
          { name: 'Bob',   date_of_birth: '1967-02-10' }
        ],
        filing_status: 'mfj',
        state: 'NY',
        start_year: 2025,
        years: 30,
        accounts: [
          { type: 'TraditionalIRA', owner: 'Alice', balance: 100_000.0 },
          { type: 'RothIRA', owner: 'Alice', balance: 50_000.0 },
          { type: 'TaxableBrokerage', owners: ['Alice','Bob'], balance: 20_000.0, cost_basis_fraction: 0.7 }
        ],
        emergency_fund_floor: 20_000.0,
        income_sources: [
          { type: 'SocialSecurityBenefit', recipient: 'Alice', pia_annual: 24_000.0, claiming_age: 67 },
          { type: 'SocialSecurityBenefit', recipient: 'Bob',   pia_annual: 24_000.0, claiming_age: 65 }
        ],
        annual_expenses: 60_000.0,
        withdrawal_hierarchy: ['taxable', 'traditional', 'roth'],
        inflation_rate: 0.02,
        growth_assumptions: { traditional_ira: 0.02, roth_ira: 0.03, taxable: 0.01, cash: 0.005 },
        strategies: [ { key: 'do_nothing' }, { key: 'fill_to_top_of_bracket' } ]
      }
      wrap_response(example)
    end
  end
end
