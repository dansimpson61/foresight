#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

module Foresight
  class LifePlanner
    YearSummary = Struct.new(:year, :strategy_name, :requested_roth_conversion, :actual_roth_conversion, :federal_tax, :capital_gains_tax, :state_tax, :effective_tax_rate, :starting_net_worth, :ending_net_worth, :ending_traditional_balance, :ending_roth_balance, :ending_taxable_balance, :rmd_taken, :narration, :magi, :irmaa_part_b, :all_in_tax, :events, :irmaa_lookback_year, :irmaa_lookback_magi, keyword_init: true)
    StrategyAggregate = Struct.new(:strategy_name, :years, :cumulative_all_in_tax, :cumulative_roth_conversions, :ending_traditional_balance, :ending_roth_balance, :ending_taxable_balance, keyword_init: true)

    def initialize(household:, start_year:, years:, growth_assumptions: {}, inflation_rate: 0.0)
      @household = household
      @start_year = start_year
      @years = years
      @growth_assumptions = default_growths.merge(growth_assumptions)
      @inflation_rate = inflation_rate.to_f
    end

    def run_multi(strategies)
      baseline_household = Marshal.load(Marshal.dump(@household))
      results = {}

      Array(strategies).each do |strategy|
        simulation_household = Marshal.load(Marshal.dump(baseline_household))
        yearly = simulate_on(simulation_household, strategy)
        aggregate = build_aggregate(yearly)
        # DIAGNOSTIC CHANGE: Prepending "DEBUG_" to the key
        results["DEBUG_#{strategy.key}"] = { yearly: yearly, aggregate: aggregate }
      end
      results
    end
    
    def to_json_report(results_hash, strategies: nil)
      inputs = build_inputs_snapshot(strategies || results_hash.keys)
      payload = {
        inputs: inputs,
        results: results_hash.transform_keys(&:to_s).transform_values do |data|
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
      { traditional_ira: 0.04, roth_ira: 0.05, taxable: 0.03, cash: 0.005 }
    end

    def build_summary(household, result, year, strategy, starting_net_worth)
      all_in = (result.federal_tax + result.capital_gains_tax + result.state_tax + result.irmaa_part_b).round(2)
      
      YearSummary.new(
        year: year,
        strategy_name: strategy.key, # Use the explicit key
        requested_roth_conversion: result.roth_conversion_requested,
        actual_roth_conversion: result.actual_roth_conversion,
        federal_tax: result.federal_tax,
        capital_gains_tax: result.capital_gains_tax,
        state_tax: result.state_tax,
        effective_tax_rate: result.effective_tax_rate,
        magi: result.magi,
        irmaa_part_b: result.irmaa_part_b,
        all_in_tax: all_in,
        starting_net_worth: starting_net_worth,
        ending_net_worth: household.net_worth,
        ending_traditional_balance: household.traditional_iras.sum(&:balance),
        ending_roth_balance: household.roth_iras.sum(&:balance),
        ending_taxable_balance: household.taxable_brokerage_accounts.sum(&:balance),
        rmd_taken: household.rmd_for(year),
        narration: result.narration,
        events: events_for(household, year)
      )
    end

    def build_aggregate(yearly)
      last = yearly.last
      StrategyAggregate.new(
        strategy_name: last.strategy_name, # This correctly uses the key from the YearSummary
        years: yearly.size,
        cumulative_all_in_tax: yearly.sum(&:all_in_tax).round(2),
        cumulative_roth_conversions: yearly.sum(&:actual_roth_conversion).round(2),
        ending_traditional_balance: last.ending_traditional_balance,
        ending_roth_balance: last.ending_roth_balance,
        ending_taxable_balance: last.ending_taxable_balance
      )
    end

    def simulate_on(household, strategy)
      summaries = []
      magi_by_year = {}
      
      @years.times do |i|
        current_year = @start_year + i
        starting_net_worth = household.net_worth
        
        tax_year = TaxYear.new(year: current_year)
        annual_planner = AnnualPlanner.new(household: household, tax_year: tax_year)
        result = annual_planner.generate_strategy(strategy)
        
        household.grow_assets(growth_assumptions: @growth_assumptions, inflation_rate: @inflation_rate)
        
        summary = build_summary(household, result, current_year, strategy, starting_net_worth)
        
        lookback_year = current_year - 2
        if magi_by_year.key?(lookback_year)
          summary.irmaa_lookback_year = lookback_year
          summary.irmaa_lookback_magi = magi_by_year[lookback_year]
        end
        summaries << summary
        
        magi_by_year[current_year] = result.magi
      end
      summaries
    end

    def build_inputs_snapshot(strategy_names)
      {
        start_year: @start_year,
        years: @years,
        inflation_rate: @inflation_rate,
        growth_assumptions: @growth_assumptions,
        members: @household.members.map do |m|
          { name: m.name, date_of_birth: m.date_of_birth.to_s }
        end,
        accounts: @household.accounts.map do |acct|
          { type: acct.class.name.split('::').last, starting_balance: acct.balance }
        end,
        strategies: Array(strategy_names)
      }
    end

    def events_for(household, year)
      evts = []
      household.members.each do |m|
        ss_benefit = household.social_security_benefits.find { |b| b.recipient == m }
        if ss_benefit && ss_benefit.claiming_age == m.age_in(year)
          evts << { type: 'ss_start', person: m.name }
        end

        evts << { type: 'medicare', person: m.name } if m.age_in(year) >= 65 && m.age_in(year - 1) < 65
        evts << { type: 'rmd_start', person: m.name } if m.rmd_eligible_in?(year) && !m.rmd_eligible_in?(year - 1)
      end
      evts
    end
  end
end
