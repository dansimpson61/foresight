# frozen_string_literal: true
require 'json'

module Foresight
  # Thin orchestration boundary for future UI / API.
  # Keeps domain planners (AnnualPlanner, LifePlanner) pure and focused.
  class PlanService
    SCHEMA_VERSION = '0.1.1' 

    StrategyDescriptor = Struct.new(:key, :klass, :description, :default_params, keyword_init: true)

    def initialize
      @registry = {}
      register_defaults
    end

    def self.run(params)
      svc = new
      plan_params = params[:inputs] || params
      svc.run_multi(plan_params)
    end

    def list_strategies
      @registry.values.map do |d|
        { key: d.key, description: d.description, default_params: d.default_params }
      end
    end

    def run_multi(params)
      household = build_household(params)
      life = LifePlanner.new(
        household: household,
        start_year: params.fetch(:start_year),
        years: params.fetch(:years),
        growth_assumptions: params[:growth_assumptions] || {},
        inflation_rate: params[:inflation_rate] || 0.0
      )
      
      strategies = params.fetch(:strategies).map { |spec| instantiate_strategy(spec) }
      
      results = life.run_multi(strategies)
      
      json = life.to_json_report(results, strategies: strategies.map(&:name))
      wrap(JSON.parse(json))
    end

    private

    def wrap(parsed_data)
      {
        schema_version: SCHEMA_VERSION,
        mode: 'multi_year',
        data: parsed_data
      }
    end

    def register_defaults
      register(
        StrategyDescriptor.new(
          key: 'do_nothing',
          klass: ConversionStrategies::NoConversion,
          description: 'Performs no Roth conversion',
          default_params: {}
        )
      )
      register(
        StrategyDescriptor.new(
          key: 'fill_to_top_of_bracket',
          klass: ConversionStrategies::BracketFill,
          description: 'Fills ordinary bracket headroom up to a specified ceiling',
          default_params: { ceiling: 94300, cushion_ratio: 0.05 }
        )
      )
    end
    
    def register(descriptor)
      @registry[descriptor.key] = descriptor
    end

    def instantiate_strategy(spec)
      key = spec[:key].to_s
      desc = @registry.fetch(key) { raise ArgumentError, "Unknown strategy key #{key}" }
      
      user_params = spec[:params] || {}
      merged_params = desc.default_params.merge(user_params)
      
      desc.klass.new(**merged_params.transform_keys(&:to_sym))
    end
    
    def build_household(params)
      members = params.fetch(:members).map { |m| Person.new(name: m[:name], date_of_birth: m[:date_of_birth]) }
      member_index = members.map { |m| [m.name, m] }.to_h

      accounts = (params[:accounts] || []).map do |a|
        case a[:type]
        when 'TraditionalIRA'
          TraditionalIRA.new(owner: member_index.fetch(a[:owner]), balance: a[:balance].to_f)
        when 'RothIRA'
          RothIRA.new(owner: member_index.fetch(a[:owner]), balance: a[:balance].to_f)
        when 'TaxableBrokerage'
          owners = a[:owners].map { |n| member_index.fetch(n) }
          TaxableBrokerage.new(owners: owners, balance: a[:balance].to_f, cost_basis_fraction: a[:cost_basis_fraction].to_f)
        when 'Cash'
          Cash.new(balance: a[:balance].to_f)
        else
          raise ArgumentError, "Unknown account type #{a[:type]}"
        end
      end

      income_sources = (params[:income_sources] || []).reject { |s| s[:annual_gross].to_i.zero? && s[:fra_benefit].to_i.zero? }.map do |s|
        recipient = member_index.fetch(s[:recipient])
        case s[:type]
        when 'Salary'
          Salary.new(recipient: recipient, annual_gross: s[:annual_gross].to_f)
        when 'Pension'
          Pension.new(recipient: recipient, annual_gross: s[:annual_gross].to_f)
        when 'SocialSecurity'
          SocialSecurityBenefit.new(
            recipient: recipient,
            pia_annual: s[:fra_benefit].to_f,
            claiming_age: s[:claiming_age].to_i
          )
        else
          raise ArgumentError, "Unknown income source type #{s[:type]}"
        end
      end

      Household.new(
        members: members,
        accounts: accounts,
        income_sources: income_sources,
        annual_expenses: params.fetch(:annual_expenses).to_f,
        emergency_fund_floor: params.fetch(:emergency_fund_floor, 0.0).to_f,
        withdrawal_hierarchy: params.fetch(:withdrawal_hierarchy, [:taxable, :traditional, :roth]).map(&:to_sym),
        filing_status: params.fetch(:filing_status, 'mfj').to_sym,
        state: params.fetch(:state, 'NY')
      )
    end
  end
end
