#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'financial_event'

module Foresight
  module ConversionStrategies
    class Base
      # A human-readable name for display purposes.
      def name
        self.class.name.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').capitalize
      end

      # A machine-readable key for use in APIs and hashes.
      def key
        name.downcase
      end
      
      # The primary contract for all strategies.
      # Given the financial state before discretionary withdrawals, this method
      # must return an array of FinancialEvent objects that represent the
      # withdrawals and conversions necessary to execute the strategy for the year.
      def plan_discretionary_events(household:, tax_year:, base_taxable_income:, spending_need:)
        raise NotImplementedError, "#{self.class.name} must implement #plan_discretionary_events"
      end
    end

    class NoConversion < Base
      def name; 'Do Nothing'; end
      def key; 'do_nothing'; end

      # This strategy is simple: meet the spending need by following the standard
      # household withdrawal hierarchy. It performs no strategic conversions.
      def plan_discretionary_events(household:, tax_year:, base_taxable_income:, spending_need:)
        return [] if spending_need <= 0
        
        allocate_spending_gap(
          need: spending_need,
          household: household,
          tax_year: tax_year,
          withdrawal_hierarchy: household.withdrawal_hierarchy
        )
      end

      private
      
      # A helper method to generate spending withdrawal events based on a given hierarchy.
      def allocate_spending_gap(need:, household:, tax_year:, withdrawal_hierarchy:)
        events = []; cash_raised = 0.0
        
        withdrawal_hierarchy.each do |account_type|
          break if cash_raised >= need
          accounts = household.accounts_by_type(account_type)
          
          accounts.each do |acct|
            break if cash_raised >= need
            available = acct.is_a?(Foresight::Cash) ? [acct.balance - household.emergency_fund_floor, 0.0].max : acct.balance
            amount_to_pull = [need - cash_raised, available].min
            next if amount_to_pull <= 0
            
            result = acct.withdraw(amount_to_pull)
            if result[:cash] > 0
              events << FinancialEvent::SpendingWithdrawal.new(
                year: tax_year.year, source_account: acct,
                amount_withdrawn: result[:cash], taxable_ordinary: result[:taxable_ordinary],
                taxable_capital_gains: result[:taxable_capital_gains]
              )
              cash_raised += result[:cash]
            end
          end
        end
        events
      end
    end

    class BracketFill < Base
      attr_reader :ceiling, :cushion_ratio

      def initialize(ceiling:, cushion_ratio: 0.05)
        @ceiling = ceiling.to_f
        @cushion_ratio = cushion_ratio.to_f
        # super() is not needed in Ruby when the parent has no initialize method
      end
      
      def name; 'Fill to Top of Bracket'; end
      def key; 'fill_to_top_of_bracket'; end

      def plan_discretionary_events(household:, tax_year:, base_taxable_income:, spending_need:)
        events = []; cash_raised = 0.0
        
        headroom = @ceiling - base_taxable_income
        return [] if headroom <= 0
        
        # Step 1: Withdraw from taxable accounts to meet spending need, up to the headroom limit.
        taxable_hierarchy = household.withdrawal_hierarchy.select { |t| [:traditional, :taxable].include?(t) }
        
        taxable_hierarchy.each do |account_type|
          break if cash_raised >= spending_need || headroom <= 0
          accounts = household.accounts_by_type(account_type)
          
          accounts.each do |acct|
            break if cash_raised >= spending_need || headroom <= 0
            
            available = acct.balance
            pull_for_spending = [spending_need - cash_raised, available].min
            
            # For taxable brokerage, the taxable impact is only a fraction of the withdrawal.
            # For traditional IRAs, the taxable impact is 1:1.
            tax_impact_ratio = acct.is_a?(Foresight::TaxableBrokerage) ? (1 - acct.cost_basis_fraction) : 1.0
            pull_limit = headroom / tax_impact_ratio
            
            amount_to_pull = [pull_for_spending, pull_limit].min
            next if amount_to_pull <= 0

            result = acct.withdraw(amount_to_pull)
            if result[:cash] > 0
              taxable_generated = result[:taxable_ordinary] + result[:taxable_capital_gains]
              headroom -= taxable_generated
              cash_raised += result[:cash]
              events << FinancialEvent::SpendingWithdrawal.new(
                year: tax_year.year, source_account: acct,
                amount_withdrawn: result[:cash], taxable_ordinary: result[:taxable_ordinary],
                taxable_capital_gains: result[:taxable_capital_gains]
              )
            end
          end
        end

        # Step 2: If headroom remains, perform a pure Roth conversion to fill the rest.
        if headroom > 0
          target_conversion = headroom * (1 - @cushion_ratio)
          available_for_conversion = household.traditional_iras.sum(&:balance)
          conversion_amount = [target_conversion, available_for_conversion].min.round(2)
          
          if conversion_amount > 0
             events.concat(perform_roth_conversion(conversion_amount, household, tax_year))
          end
        end
        
        # Step 3: If spending need is still unmet, pull from non-taxable accounts.
        if cash_raised < spending_need
          non_taxable_hierarchy = household.withdrawal_hierarchy.select { |t| [:roth, :cash].include?(t) }
          non_taxable_events = allocate_spending_gap(
            need: spending_need - cash_raised,
            household: household,
            tax_year: tax_year,
            withdrawal_hierarchy: non_taxable_hierarchy
          )
          events.concat(non_taxable_events)
        end

        events
      end

      private

      # Helper to create RothConversion events.
      def perform_roth_conversion(amount, household, tax_year)
        events = []; remaining = amount
        household.traditional_iras.each do |acct|
          break if remaining <= 0
          pulled = [remaining, acct.balance].min
          dest = household.roth_iras.find { |r| r.owner == acct.owner }
          next unless dest
          
          result = acct.convert_to_roth(pulled)
          if result[:converted] > 0
            events << FinancialEvent::RothConversion.new(
              year: tax_year.year, source_account: acct,
              destination_account: dest, amount: result[:converted]
            )
            remaining -= result[:converted]
          end
        end
        events
      end
      
      # A helper method to generate spending withdrawal events based on a given hierarchy.
      def allocate_spending_gap(need:, household:, tax_year:, withdrawal_hierarchy:)
        events = []; cash_raised = 0.0
        
        withdrawal_hierarchy.each do |account_type|
          break if cash_raised >= need
          accounts = household.accounts_by_type(account_type)
          
          accounts.each do |acct|
            break if cash_raised >= need
            available = acct.is_a?(Foresight::Cash) ? [acct.balance - household.emergency_fund_floor, 0.0].max : acct.balance
            amount_to_pull = [need - cash_raised, available].min
            next if amount_to_pull <= 0
            
            result = acct.withdraw(amount_to_pull)
            if result[:cash] > 0
              events << FinancialEvent::SpendingWithdrawal.new(
                year: tax_year.year, source_account: acct,
                amount_withdrawn: result[:cash], taxable_ordinary: result[:taxable_ordinary],
                taxable_capital_gains: result[:taxable_capital_gains]
              )
              cash_raised += result[:cash]
            end
          end
        end
        events
      end
    end
  end
end
