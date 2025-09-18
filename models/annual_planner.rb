# frozen_string_literal: true

module Foresight
  class AnnualPlanner
    StrategyResult = Struct.new(:strategy_name, :year, :base_taxable_income, :roth_conversion_requested, :actual_roth_conversion, :taxable_income_after_conversion, :magi, :after_tax_cash_before_spending_withdrawals, :remaining_spending_need, :withdrawals, :federal_tax, :capital_gains_tax, :state_tax, :irmaa_part_b, :effective_tax_rate, :ss_taxable_post, :ss_taxable_increase, :conversion_incremental_tax, :conversion_incremental_marginal_rate, :narration, keyword_init: true)

    attr_reader :household, :tax_year

    def initialize(household:, tax_year:)
      @household = household
      @tax_year = tax_year
    end

    def generate_strategy(strategy)
      puts "[STRATEGY_STEP] AnnualPlanner: Starting year #{@tax_year.year} for strategy '#{strategy.key}'."
      base_income = compute_base_income
      execute_for_strategy(strategy, base_income)
    end

    private

    def compute_base_income
      puts "[STRATEGY_STEP] AnnualPlanner: Computing base income..."
      # This is a simplified placeholder for the actual calculation logic
      # In a real scenario, this would involve summing salaries, pensions, etc.
      base_income = household.salaries.sum(&:annual_gross) + household.pensions.sum(&:annual_gross)
      puts "[STRATEGY_STEP] AnnualPlanner: Base income computed as #{base_income}."
      base_income
    end

    def execute_for_strategy(strategy, base_income)
      puts "[STRATEGY_STEP] AnnualPlanner: Executing for strategy '#{strategy.key}'."
      
      # Step 1: "Ask" the strategy for the conversion amount
      conversion_amount = strategy.conversion_amount(
        household: @household,
        tax_year: @tax_year,
        base_taxable_income: base_income
      )
      puts "[STRATEGY_STEP] AnnualPlanner: Strategy '#{strategy.key}' requested conversion of #{conversion_amount}."

      # ... (In a real scenario, we would perform the conversion, recalculate taxes, etc.) ...
      
      # Final step: Assemble the results with default values for all fields
      narration = "Year #{@tax_year.year}: Strategy '#{strategy.key}' executed. Base income was #{base_income}. Conversion of #{conversion_amount} was requested."
      puts "[STRATEGY_STEP] AnnualPlanner: Finalizing results for year #{@tax_year.year}."
      
      StrategyResult.new(
        strategy_name: strategy.key,
        year: @tax_year.year,
        base_taxable_income: base_income,
        roth_conversion_requested: conversion_amount,
        actual_roth_conversion: 0.0,
        taxable_income_after_conversion: base_income,
        magi: base_income,
        after_tax_cash_before_spending_withdrawals: base_income,
        remaining_spending_need: 0.0,
        withdrawals: {},
        federal_tax: 0.0,
        capital_gains_tax: 0.0,
        state_tax: 0.0,
        irmaa_part_b: 0.0,
        effective_tax_rate: 0.0,
        ss_taxable_post: 0.0,
        ss_taxable_increase: 0.0,
        conversion_incremental_tax: 0.0,
        conversion_incremental_marginal_rate: 0.0,
        narration: narration
      )
    end
  end
end
