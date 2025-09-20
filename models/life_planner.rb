#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

module Foresight
  class LifePlanner
    YearSummary = Struct.new(:year, :strategy_name, :taxable_income_breakdown, :tax_brackets, :federal_tax, :capital_gains_tax, :state_tax, :effective_tax_rate, :starting_balance, :starting_net_worth, :ending_balance, :ending_net_worth, :ending_traditional_balance, :ending_roth_balance, :ending_taxable_balance, :rmd_taken, :narration, :future_rmd_pressure, :ss_taxable_post, :ss_taxable_increase, :magi, :irmaa_part_b, :all_in_tax, :events, :irmaa_lookback_year, :irmaa_lookback_magi, :financial_events, keyword_init: true)
    StrategyAggregate = Struct.new(:strategy_name, :years, :cumulative_federal_tax, :cumulative_capital_gains_tax, :cumulative_all_in_tax, :cumulative_roth_conversions, :cumulative_irmaa_surcharges, :ending_balances, :projected_first_rmd_pressure, keyword_init: true)


    attr_reader :household

    def initialize(household:, start_year:, years:, growth_assumptions: {}, inflation_rate: 0.0)
      @household = household
      @start_year = start_year
      @years = years
      @growth_assumptions = default_growths.merge(growth_assumptions)
      @inflation_rate = inflation_rate.to_f
      @initial_account_balances = household.accounts.each_with_object({}) do |acct, h|
        h[acct.object_id] = acct.balance
      end
      @initial_annual_expenses = household.annual_expenses
    end

    def run_multi(strategies)
      strategies = Array(strategies)
      baseline = snapshot_household(@household)
      results = {}
      strategies.each do |strategy|
        restore_household(@household, baseline)
        yearly = simulate_on(@household, strategy)
        aggregate = build_aggregate(yearly)
        results[strategy.key] = { 
          yearly: yearly.map(&:to_h), 
          aggregate: aggregate.to_h 
        }
      end
      results
    end
    
    def to_json_report(results_hash, strategies: nil)
      inputs = build_inputs_snapshot(strategies || results_hash.keys)
      payload = {
        inputs: inputs,
        results: results_hash.transform_values do |data|
          {
            aggregate: data[:aggregate],
            yearly: data[:yearly]
          }
        end
      }
      JSON.pretty_generate(payload)
    end

    private

    def default_growths
      { traditional_ira: 0.04, roth_ira: 0.05, taxable: 0.03, cash: 0.005 }
    end

    def apply_growth
      @household.grow_assets(growth_assumptions: @growth_assumptions, inflation_rate: @inflation_rate)
    end

    def build_summary(result, year, strategy, starting_balances)
      all_in = (result.federal_tax + result.capital_gains_tax + result.state_tax + result.irmaa_part_b).round(2)
      ending_balances = {
        traditional: @household.traditional_iras.sum(&:balance).round(2),
        roth: @household.roth_iras.sum(&:balance).round(2),
        taxable: @household.taxable_brokerage_accounts.sum(&:balance).round(2),
        cash: @household.cash_accounts.sum(&:balance).round(2)
      }
      
      rmd_events = result.financial_events.select { |e| e.is_a?(FinancialEvent::RequiredMinimumDistribution) }
      
      YearSummary.new(
        year: year,
        strategy_name: strategy.name,
        taxable_income_breakdown: result.taxable_income_breakdown,
        tax_brackets: result.tax_brackets,
        federal_tax: result.federal_tax,
        capital_gains_tax: result.capital_gains_tax,
        state_tax: result.state_tax,
        effective_tax_rate: result.effective_tax_rate,
        magi: result.magi,
        irmaa_part_b: result.irmaa_part_b,
        all_in_tax: all_in,
        
        starting_balance: starting_balances.values.sum.round(2),
        starting_net_worth: starting_balances.values.sum.round(2),
        
        ending_balance: ending_balances.values.sum.round(2),
        ending_net_worth: ending_balances.values.sum.round(2),
        ending_traditional_balance: ending_balances[:traditional],
        ending_roth_balance: ending_balances[:roth],
        ending_taxable_balance: ending_balances[:taxable],
        
        rmd_taken: rmd_events.sum(&:amount).round(2),
        narration: result.narration,
        future_rmd_pressure: future_rmd_pressure(year + 1),
        ss_taxable_post: result.ss_taxable_post,
        ss_taxable_increase: result.ss_taxable_increase,
        events: events_for(year),
        financial_events: result.financial_events, # Store the actual event objects
        irmaa_lookback_year: nil,
        irmaa_lookback_magi: nil
      )
    end

    def future_rmd_pressure(target_year)
      projected_rmd = @household.traditional_iras.sum do |acct|
        age = acct.owner.age_in(target_year)
        acct.calculate_rmd(age)
      end
      spending = @household.annual_expenses
      return 0.0 if spending <= 0
      (projected_rmd / spending).round(4)
    end

    def projected_first_rmd_pressure_for(household)
      0.0 
    end

    def build_aggregate(yearly)
        last = yearly.last
        # Retrieve the actual event objects before processing
        all_financial_events = yearly.flat_map(&:financial_events)
        
        total_conversions = all_financial_events
          .select { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
          .sum(&:amount)
          .round(2)
  
        StrategyAggregate.new(
          strategy_name: last.strategy_name,
          years: yearly.size,
          cumulative_federal_tax: yearly.sum(&:federal_tax).round(2),
          cumulative_capital_gains_tax: yearly.sum(&:capital_gains_tax).round(2),
          cumulative_all_in_tax: yearly.sum(&:all_in_tax).round(2),
          cumulative_roth_conversions: total_conversions,
          cumulative_irmaa_surcharges: yearly.sum(&:irmaa_part_b).round(2),
          ending_balances: {
            roth: last.ending_roth_balance,
            traditional: last.ending_traditional_balance,
            taxable: last.ending_taxable_balance
          },
          projected_first_rmd_pressure: 0.0
        )
      end

    def simulate_on(household, strategy)
      summaries = []
      current_year = @start_year
      magi_by_year = {}
      @years.times do
        starting_balances = {
          traditional: household.traditional_iras.sum(&:balance),
          roth: household.roth_iras.sum(&:balance),
          taxable: household.taxable_brokerage_accounts.sum(&:balance),
          cash: household.cash_accounts.sum(&:balance)
        }
        
        tax_year = TaxYear.new(year: current_year)
        annual_planner = AnnualPlanner.new(household: household, tax_year: tax_year)
        result = annual_planner.generate_strategy(strategy)
        
        apply_growth
        
        summary = build_summary(result, current_year, strategy, starting_balances)
        
        lookback_year = current_year - 2
        if magi_by_year.key?(lookback_year)
          summary.irmaa_lookback_year = lookback_year
          summary.irmaa_lookback_magi = magi_by_year[lookback_year].round(2)
        end
        summaries << summary
        
        magi_by_year[current_year] = result.magi
        current_year += 1
      end
      summaries
    end

    def snapshot_household(hh)
      {
        annual_expenses: hh.annual_expenses,
        accounts: hh.accounts.map { |a| [a, Marshal.load(Marshal.dump(a.balance))] }
      }
    end

    def build_inputs_snapshot(strategy_names)
      {
        start_year: @start_year,
        years: @years,
        inflation_rate: @inflation_rate,
        growth_assumptions: @growth_assumptions,
        household: {
          filing_status: @household.filing_status,
          state: @household.state,
          annual_expenses_start: @initial_annual_expenses,
          emergency_fund_floor: @household.emergency_fund_floor,
          withdrawal_hierarchy: @household.withdrawal_hierarchy,
        },
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
          when 'Salary'
            h[:annual_gross] = src.annual_gross
          when 'Pension'
            h[:annual_gross] = src.annual_gross
          when 'SocialSecurityBenefit'
            h[:pia_annual] = src.pia_annual
            h[:claiming_age] = src.claiming_age
          end
          h
        end,
        strategies: Array(strategy_names)
      }
    end

    def restore_household(hh, snap)
      hh.instance_variable_set(:@annual_expenses, snap[:annual_expenses])
      snap[:accounts].each do |acct_ref, balance|
        acct_ref.instance_variable_set(:@balance, balance)
      end
    end

    def events_for(year)
      evts = []
      @household.social_security_benefits.each do |b|
        evts << { type: 'ss_start', person: b.recipient.name } if b.recipient.age_in(year) == b.claiming_age
      end
      @household.members.each do |m|
        evts << { type: 'medicare', person: m.name } if m.age_in(year) >= 65 && m.age_in(year - 1) < 65
      end
      @household.members.each do |m|
        evts <<({ type: 'rmd_start', person: m.name }) if m.rmd_eligible_in?(year) && !m.rmd_eligible_in?(year - 1)
      end
      evts
    end
  end
end
