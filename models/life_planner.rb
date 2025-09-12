#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

module Foresight
  class LifePlanner
    YearSummary = Struct.new(
      :year,
      :strategy_name,
      :requested_roth_conversion,
      :actual_roth_conversion,
      :federal_tax,
      :capital_gains_tax,
  :state_tax,
      :effective_tax_rate,
      :ending_traditional_balance,
      :ending_roth_balance,
      :ending_taxable_balance,
      :rmd_taken,
      :narration,
      :future_rmd_pressure,
      :ss_taxable_post,
      :ss_taxable_increase,
      :conversion_incremental_tax,
      :conversion_incremental_marginal_rate,
  :magi,
  :irmaa_part_b,
  :all_in_tax,
  :events,
  :irmaa_lookback_year,
  :irmaa_lookback_magi,
      keyword_init: true
    )

    StrategyAggregate = Struct.new(
      :strategy_name,
      :years,
      :cumulative_federal_tax,
      :cumulative_capital_gains_tax,
  :cumulative_all_in_tax,
      :cumulative_roth_conversions,
      :ending_traditional_balance,
      :ending_roth_balance,
      :ending_taxable_balance,
      :projected_first_rmd_pressure,
      keyword_init: true
    )

    attr_reader :household

    def initialize(household:, start_year:, years:, growth_assumptions: {}, inflation_rate: 0.0)
      @household = household
      @start_year = start_year
      @years = years
      @growth_assumptions = default_growths.merge(growth_assumptions)
      @inflation_rate = inflation_rate.to_f
      # Capture true initial balances once for reporting
      @initial_account_balances = household.accounts.each_with_object({}) do |acct, h|
        h[acct.object_id] = acct.balance
      end
  @initial_target_spending = household.target_spending_after_tax
    end

    def run(strategy: ConversionStrategies::BracketFill.new)
      simulate_on(@household, strategy)
    end

    # Run multiple strategies from the SAME starting state (deep-cloned) and return
    # { per_strategy: { name => { yearly: [...], aggregate: StrategyAggregate } } }
    def run_multi(strategies)
      strategies = Array(strategies)
      baseline = snapshot_household(@household)
      results = {}
      strategies.each do |strategy|
        restore_household(@household, baseline)
        yearly = simulate_on(@household, strategy)
        aggregate = build_aggregate(yearly)
        results[strategy.name] = { yearly: yearly, aggregate: aggregate }
      end
      results
    end
    
    def to_json_report(results_hash, strategies: nil)
      # Build an input snapshot only once (before mutation side-effects; assumes caller cloned or just finished run_multi)
      inputs = build_inputs_snapshot(strategies || results_hash.keys)
      payload = {
        inputs: inputs,
        results: results_hash.transform_values do |data|
          {
            aggregate: data[:aggregate].to_h,
            yearly: data[:yearly].map(&:to_h)
          }
        end
      }
      JSON.pretty_generate(payload)
    end

    private

    def default_growths
      { traditional_ira: 0.04, roth_ira: 0.05, taxable: 0.03 }
    end

    def apply_growth
      @household.grow_assets(growth_assumptions: @growth_assumptions, inflation_rate: @inflation_rate)
    end

    def build_summary(result, year, strategy)
      all_in = (result.federal_tax.to_f + result.capital_gains_tax.to_f + result.state_tax.to_f + result.irmaa_part_b.to_f).round(2)
      YearSummary.new(
        year: year,
        strategy_name: strategy.name,
        requested_roth_conversion: result.roth_conversion_requested,
        actual_roth_conversion: result.actual_roth_conversion,
        federal_tax: result.federal_tax,
        capital_gains_tax: result.capital_gains_tax,
  state_tax: result.state_tax,
        effective_tax_rate: result.effective_tax_rate,
  magi: result.magi,
  irmaa_part_b: result.irmaa_part_b,
        all_in_tax: all_in,
        ending_traditional_balance: @household.traditional_iras.sum(&:balance).round(2),
        ending_roth_balance: @household.roth_iras.sum(&:balance).round(2),
        ending_taxable_balance: @household.taxable_brokerage_accounts.sum(&:balance).round(2),
        rmd_taken: @household.traditional_iras.sum { |acct| acct.calculate_rmd(acct.owner.age_in(year)) }.round(2),
        narration: result.narration,
        future_rmd_pressure: future_rmd_pressure(year + 1),
        ss_taxable_post: result.ss_taxable_post,
        ss_taxable_increase: result.ss_taxable_increase,
        conversion_incremental_tax: result.conversion_incremental_tax,
  conversion_incremental_marginal_rate: result.conversion_incremental_marginal_rate,
  events: events_for(year),
  irmaa_lookback_year: nil,        # filled in simulate_on when history exists
  irmaa_lookback_magi: nil         # filled in simulate_on when history exists
      )
    end

    def future_rmd_pressure(target_year)
      projected_rmd = @household.traditional_iras.sum do |acct|
        age = acct.owner.age_in(target_year)
        acct.calculate_rmd(age)
      end
      spending = @household.target_spending_after_tax
      return 0.0 if spending <= 0
      (projected_rmd / spending.to_f).round(4)
    end

    # Compute pressure at first RMD year (simplified 73) using growth projection forward
    def projected_first_rmd_pressure_for(household)
  first_rmd_age = @household.members.map(&:rmd_start_age).min
      trad_growth = 1 + @growth_assumptions[:traditional_ira]
      projected_trad_total = 0.0
      future_spending = household.target_spending_after_tax
      # Assume inflation applied each future year
      household.traditional_iras.each do |acct|
        current_age = acct.owner.age_in(@start_year + @years - 1) # end age after simulation
        years_until_rmd = [first_rmd_age - current_age, 0].max
        balance = acct.balance * (trad_growth ** years_until_rmd)
        projected_trad_total += balance
        future_spending *= ((1 + @inflation_rate) ** years_until_rmd)
      end
      # Use divisor at first RMD age for first owner (approx)
      divisor = TraditionalIRA::RMD_TABLE[first_rmd_age] || 26.5
      projected_rmd = projected_trad_total / divisor
      return 0.0 if future_spending <= 0
      (projected_rmd / future_spending).round(4)
    end

    def build_aggregate(yearly)
      last = yearly.last
      StrategyAggregate.new(
        strategy_name: last.strategy_name,
        years: yearly.size,
        cumulative_federal_tax: yearly.sum(&:federal_tax).round(2),
        cumulative_capital_gains_tax: yearly.sum(&:capital_gains_tax).round(2),
  cumulative_all_in_tax: yearly.sum { |y| y.all_in_tax.to_f }.round(2),
        cumulative_roth_conversions: yearly.sum { |y| y.actual_roth_conversion }.round(2),
        ending_traditional_balance: last.ending_traditional_balance,
        ending_roth_balance: last.ending_roth_balance,
        ending_taxable_balance: last.ending_taxable_balance,
        projected_first_rmd_pressure: projected_first_rmd_pressure_for(@household)
      )
    end

    def snapshot_household(hh)
      {
        target: hh.target_spending_after_tax,
        accounts: hh.accounts.map { |a| [a, Marshal.load(Marshal.dump(a.balance))] }
      }
    end

    def build_inputs_snapshot(strategy_names)
      {
        start_year: @start_year,
        years: @years,
        inflation_rate: @inflation_rate,
        growth_assumptions: @growth_assumptions,
        members: @household.members.map do |m|
          {
            name: m.name,
            date_of_birth: m.date_of_birth.to_s,
            age_in_start_year: m.age_in(@start_year)
          }
        end,
        accounts: @household.accounts.map do |acct|
          type = acct.class.name.split('::').last
          starting_balance = @initial_account_balances[acct.object_id] || acct.balance
          base = { type: type, owner: (acct.respond_to?(:owner) && acct.owner ? acct.owner.name : nil), owners: (acct.respond_to?(:owners) ? acct.owners.map(&:name) : nil), starting_balance: starting_balance }
          if type == 'TaxableBrokerage' && acct.respond_to?(:cost_basis_fraction)
            base[:cost_basis_fraction] = acct.cost_basis_fraction
          end
          base
        end,
        income_sources: @household.income_sources.map do |src|
          t = src.class.name.split('::').last
            h = { type: t, recipient: src.recipient.name }
          case t
          when 'Pension'
            h[:annual_gross] = src.annual_gross
          when 'SocialSecurityBenefit'
            if src.instance_variable_defined?(:@pia_annual) && src.instance_variable_get(:@pia_annual)
              h[:pia_annual] = src.instance_variable_get(:@pia_annual)
            end
            if src.instance_variable_defined?(:@given_claimed_amount) && src.instance_variable_get(:@given_claimed_amount)
              h[:claimed_annual_at_start] = src.instance_variable_get(:@given_claimed_amount)
            end
            h[:start_year] = src.start_year
            h[:cola_rate] = src.cola_rate
          end
          h
        end,
  target_spending_after_tax_start: @initial_target_spending,
        desired_tax_bracket_ceiling: @household.desired_tax_bracket_ceiling,
        strategies: Array(strategy_names)
      }
    end

    def restore_household(hh, snap)
      hh.instance_variable_set(:@target_spending_after_tax, snap[:target])
      snap[:accounts].each do |acct_ref, balance|
        acct_ref.instance_variable_set(:@balance, balance)
      end
    end

    def simulate_on(household, strategy)
      summaries = []
      current_year = @start_year
      magi_by_year = {}
      @years.times do
        tax_year = TaxYear.new(year: current_year)
        annual_planner = AnnualPlanner.new(household: household, tax_year: tax_year)
        result = annual_planner.generate_strategy(strategy)
        apply_growth
        summary = build_summary(result, current_year, strategy)
        # Attach IRMAA lookback (2-year prior) for UI timeline purposes
        lookback_year = current_year - 2
        if magi_by_year.key?(lookback_year)
          summary.irmaa_lookback_year = lookback_year
          summary.irmaa_lookback_magi = magi_by_year[lookback_year].round(2)
        end
        summaries << summary
        # Record MAGI after building summary to avoid off-by-one confusion
        magi_by_year[current_year] = result.magi.to_f
        current_year += 1
      end
      summaries
    end

    # --- Events for UI annotations (lightweight, derived from domain state) ---
    # Returns an array of hashes like: { type: 'ss_start'|'medicare'|'rmd_start', person: 'Name' }
    def events_for(year)
      evts = []
      # Social Security claiming starts
      @household.social_security_benefits.each do |b|
        evts << { type: 'ss_start', person: b.recipient.name } if b.start_year == year
      end
      # Medicare Part B enrollment at age 65 (approx)
      @household.members.each do |m|
        evts << { type: 'medicare', person: m.name } if m.age_in(year) >= 65 && m.age_in(year - 1) < 65
      end
      # First RMD eligibility (SECURE 2.0 ages handled by Person)
      @household.members.each do |m|
        evts <<({ type: 'rmd_start', person: m.name }) if m.rmd_eligible_in?(year) && !m.rmd_eligible_in?(year - 1)
      end
      evts
    end
  end
end
