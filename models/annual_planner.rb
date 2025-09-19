# frozen_string_literal: true

module Foresight
  class AnnualPlanner
    # ... (Struct) ...
    def execute_for_strategy(strategy, base_income)
      puts "--- AnnualPlanner: Year #{@tax_year.year} ---"
      available_before = household.traditional_iras.sum(&:balance)
      
      requested = strategy.conversion_amount(
        household: @household,
        tax_year: @tax_year,
        base_taxable_income: base_income
      )
      
      actual = [requested, available_before].min
      puts "Available: #{available_before}, Requested: #{requested}, Actual: #{actual}"
      
      if actual > 0
        household.traditional_iras.first.withdraw(actual)
        household.roth_iras.first.deposit(actual)
      end
      
      StrategyResult.new(
        actual_roth_conversion: actual,
        # ... other fields
      )
    end
  end
end
