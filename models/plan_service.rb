# frozen_string_literal: true
require 'json'

module Foresight
  # Thin orchestration boundary for future UI / API.
  # Keeps domain planners (AnnualPlanner, LifePlanner) pure and focused.
  class PlanService
    SCHEMA_VERSION = '0.1.0'

    StrategyDescriptor = Struct.new(:key, :klass, :description, :default_params, keyword_init: true)

    def initialize
      @registry = {}
      register_defaults
    end

    # Unified entrypoint: PlanService.run(params) -> Hash
    # Auto-selects single vs multi-year based on :years and :strategies unless :mode provided.
    def self.run(params)
      svc = new
      # If params are nested under :inputs, elevate them. Handles report-style inputs.
      plan_params = params[:inputs] || params
      mode = plan_params[:mode]
      
      case mode
      when 'single_year'
        svc.run_single(plan_params)
      when 'multi_year'
        svc.run_multi(plan_params)
      else
        if plan_params[:years].to_i > 1 || plan_params[:strategies]
          svc.run_multi(plan_params)
        else
          svc.run_single(plan_params)
        end
      end
    end

    def list_strategies
      @registry.values.map do |d|
        { key: d.key, description: d.description, default_params: d.default_params }
      end
    end

    # params: {
    #   members: [{ name:, date_of_birth: }],
    #   accounts: [{ type:, owner:, owners:, balance:, cost_basis_fraction: }],
    #   income_sources: [{ type:, recipient:, start_year:, pia_annual:, annual_benefit:, cola_rate: }],
    #   target_spending_after_tax:, desired_tax_bracket_ceiling:,
    #   start_year:, years:, inflation_rate:, growth_assumptions: {},
    #   strategies: [{ key:, params: {} }]
    # }
    def run_multi(params)
      household = build_household(params)
      life = LifePlanner.new(
        household: household,
        start_year: params.fetch(:start_year),
        years: params.fetch(:years),
        growth_assumptions: params[:growth_assumptions] || {},
        inflation_rate: params[:inflation_rate] || 0.0
      )
      strategies = (params[:strategies] || default_strategy_specs).map { |spec| instantiate_strategy(spec) }
      results = life.run_multi(strategies)
      json = life.to_json_report(results, strategies: strategies.map(&:name))
      enriched = inject_phases(JSON.parse(json), life, results)
      wrap(enriched)
    end

    def run_single(params)
      household = build_household(params)
      strategy = instantiate_strategy((params[:strategy] || { key: 'bracket_fill' }))
      tax_year = TaxYear.new(year: params.fetch(:start_year))
      annual = AnnualPlanner.new(household: household, tax_year: tax_year)
      result = annual.generate_strategy(strategy)
      {
        schema_version: SCHEMA_VERSION,
        mode: 'single_year',
        result: result.to_h
      }
    end

    private

    def wrap(parsed_data)
      {
        schema_version: SCHEMA_VERSION,
        mode: 'multi_year',
        data: parsed_data
      }
    end

    def inject_phases(parsed, life, raw_results)
      parsed_results = parsed['results']
      parsed_results.each do |strategy_name, bundle|
        yearly_rows = bundle['yearly']
        # Convert to symbol-keyed hashes for analyzer
        sym_rows = yearly_rows.map { |h| h.transform_keys { |k| k.to_s.downcase.to_sym rescue k } }
        initial_trad = sym_rows.first ? sym_rows.first[:ending_traditional_balance].to_f : 0.0
        analyzer = PhaseAnalyzer.new(initial_traditional_total: initial_trad)
        phases = analyzer.analyze(sym_rows)
        bundle['phases'] = phases.map do |p|
          { name: p.name, start_year: p.start_year, end_year: p.end_year, metrics: p.metrics }
        end
      end
      parsed
    end

    def register_defaults
      register(
        StrategyDescriptor.new(
          key: 'none',
          klass: ConversionStrategies::NoConversion,
          description: 'Performs no Roth conversion',
          default_params: {}
        )
      )
      register(
        StrategyDescriptor.new(
          key: 'bracket_fill',
          klass: ConversionStrategies::BracketFill,
          description: 'Fills ordinary bracket headroom up to household ceiling with cushion',
          default_params: { cushion_ratio: 0.05 }
        )
      )
    end

    def register(descriptor)
      @registry[descriptor.key] = descriptor
    end

    def default_strategy_specs
      [
        { key: 'none' },
        { key: 'bracket_fill' }
      ]
    end

    def instantiate_strategy(spec)
      desc = @registry.fetch(spec[:key]) { raise ArgumentError, "Unknown strategy key #{spec[:key]}" }
      params = (spec[:params] || {}).empty? ? desc.default_params : desc.default_params.merge(spec[:params])
      # Only BracketFill currently has params
      if desc.klass == ConversionStrategies::BracketFill
        return desc.klass.new(**params.transform_keys(&:to_sym))
      end
      desc.klass.new
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
          TaxableBrokerage.new(owners: owners, balance: a[:balance].to_f, cost_basis_fraction: a[:cost_basis_fraction].to_f || 0.7)
        else
          raise ArgumentError, "Unknown account type #{a[:type]}"
        end
      end
      income_sources = (params[:income_sources] || []).map do |s|
        case s[:type]
        when 'Pension'
          Pension.new(recipient: member_index.fetch(s[:recipient]), annual_gross: s[:annual_gross].to_f)
        when 'SocialSecurityBenefit'
          SocialSecurityBenefit.new(
            recipient: member_index.fetch(s[:recipient]),
            start_year: s[:start_year],
            annual_benefit: s[:annual_benefit].to_f,
            pia_annual: s[:pia_annual].to_f,
            cola_rate: s[:cola_rate].to_f || 0.0
          )
        else
          raise ArgumentError, "Unknown income source type #{s[:type]}"
        end
      end
      Household.new(
        members: members,
        target_spending_after_tax: params.fetch(:target_spending_after_tax).to_f,
        desired_tax_bracket_ceiling: params.fetch(:desired_tax_bracket_ceiling).to_f,
        accounts: accounts,
        income_sources: income_sources
      )
    end
  end
end
