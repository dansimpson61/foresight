#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'conversion_strategies'

module Foresight
  module ConversionStrategies
    # This is a base class for all conditional strategies.
    class ConditionalBase < Base
      def plan_discretionary_events(household:, tax_year:, base_taxable_income:, spending_need:, ss_total: 0.0, provisional_income_before_strategy: 0.0, standard_deduction: 0.0)
        # If Social Security benefits are being received, do not perform any conversion.
        # Fall back to the baseline strategy of just meeting spending needs.
        if ss_total > 0
          return NoConversion.new.plan_discretionary_events(
            household: household, tax_year: tax_year, base_taxable_income: base_taxable_income,
            spending_need: spending_need, ss_total: ss_total,
            provisional_income_before_strategy: provisional_income_before_strategy,
            standard_deduction: standard_deduction
          )
        end

        # If the year is outside the specified range for time-bound strategies, do nothing.
        if respond_to?(:start_year) && tax_year.year < start_year
          return NoConversion.new.plan_discretionary_events(
            household: household, tax_year: tax_year, base_taxable_income: base_taxable_income,
            spending_need: spending_need, ss_total: ss_total,
            provisional_income_before_strategy: provisional_income_before_strategy,
            standard_deduction: standard_deduction
          )
        end
        if respond_to?(:end_year) && tax_year.year > end_year
            return NoConversion.new.plan_discretionary_events(
                household: household, tax_year: tax_year, base_taxable_income: base_taxable_income,
                spending_need: spending_need, ss_total: ss_total,
                provisional_income_before_strategy: provisional_income_before_strategy,
                standard_deduction: standard_deduction
              )
        end
        
        # If conditions are met, proceed with the actual strategy logic.
        plan_conditional_events(
          household: household, tax_year: tax_year, base_taxable_income: base_taxable_income,
          spending_need: spending_need, ss_total: ss_total,
          provisional_income_before_strategy: provisional_income_before_strategy,
          standard_deduction: standard_deduction
        )
      end
    end

    # Fills a tax bracket, but only in years where no Social Security is claimed.
    class ConditionalBracketFill < ConditionalBase
      attr_reader :ceiling, :cushion_ratio
      def initialize(ceiling:, cushion_ratio: 0.05)
        @ceiling = ceiling
        @cushion_ratio = cushion_ratio
      end

      def name; 'Fill Bracket (No SS Years)'; end
      def key; 'fill_bracket_no_ss'; end

      def plan_conditional_events(household:, tax_year:, base_taxable_income:, spending_need:, ss_total: 0.0, provisional_income_before_strategy: 0.0, standard_deduction: 0.0)
        BracketFill.new(ceiling: @ceiling, cushion_ratio: @cushion_ratio).plan_discretionary_events(
          household: household, tax_year: tax_year, base_taxable_income: base_taxable_income,
          spending_need: spending_need, ss_total: ss_total,
          provisional_income_before_strategy: provisional_income_before_strategy,
          standard_deduction: standard_deduction
        )
      end
    end

    # Fills a tax bracket, but only within a specified year range and in years with no SS.
    class ConditionalBracketFillByYear < ConditionalBracketFill
      attr_reader :start_year, :end_year

      def initialize(ceiling:, cushion_ratio: 0.05, start_year:, end_year:)
        super(ceiling: ceiling, cushion_ratio: cushion_ratio)
        @start_year = start_year
        @end_year = end_year
      end
      
      def name; 'Fill Bracket by Year (No SS Years)'; end
      def key; 'fill_bracket_by_year_no_ss'; end
    end

    # Converts a fixed amount, but only in years where no Social Security is claimed.
    class ConditionalFixedAmount < ConditionalBase
      attr_reader :amount

      def initialize(amount:)
        @amount = amount.to_f
      end
      
      def name; 'Fixed Amount (No SS Years)'; end
      def key; 'fixed_amount_no_ss'; end

      def plan_conditional_events(household:, tax_year:, base_taxable_income:, spending_need:, ss_total: 0.0, provisional_income_before_strategy: 0.0, standard_deduction: 0.0)
        events = []
        
        # Step 1: Fulfill Spending Needs first.
        if spending_need > 0
          spending_events = allocate_spending_gap(
            need: spending_need, household: household, tax_year: tax_year,
            withdrawal_hierarchy: household.withdrawal_hierarchy
          )
          events.concat(spending_events)
        end

        # Step 2: Perform the fixed conversion if funds are available.
        available = household.traditional_iras.sum(&:balance)
        conversion_amount = [@amount, available].min.round(2)
        
        if conversion_amount > 0
          events.concat(perform_roth_conversion(conversion_amount, household, tax_year))
        end

        events
      end
    end

    # Converts a fixed amount, but only within a specified year range and in years with no SS.
    class ConditionalFixedAmountByYear < ConditionalFixedAmount
      attr_reader :start_year, :end_year

      def initialize(amount:, start_year:, end_year:)
        super(amount: amount)
        @start_year = start_year
        @end_year = end_year
      end

      def name; 'Fixed Amount by Year (No SS Years)'; end
      def key; 'fixed_amount_by_year_no_ss'; end
    end
  end
end
