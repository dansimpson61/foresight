#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'financial_event'

module Foresight
  module ConversionStrategies
    # Defines the interface for all conversion strategies.
    class Base
      def name
        self.class.name.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').capitalize
      end

      def key
        name.downcase
      end
      
      # The primary contract. Must be implemented by all subclasses.
      def plan_discretionary_events(household:, tax_year:, base_taxable_income:, spending_need:, ss_total: 0.0, provisional_income_before_strategy: 0.0, standard_deduction: 0.0)
        raise NotImplementedError, "#{self.class.name} must implement #plan_discretionary_events"
      end

      # A contract for conditional strategies.
      def plan_conditional_events(household:, tax_year:, base_taxable_income:, spending_need:, ss_total: 0.0, provisional_income_before_strategy: 0.0, standard_deduction: 0.0)
        plan_discretionary_events(
          household: household, tax_year: tax_year, base_taxable_income: base_taxable_income,
          spending_need: spending_need, ss_total: ss_total,
          provisional_income_before_strategy: provisional_income_before_strategy,
          standard_deduction: standard_deduction
        )
      end

      protected

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

      # Helper to create RothConversion events from available Traditional IRA funds.
      def perform_roth_conversion(amount, household, tax_year)
        events = []; remaining = amount
        household.traditional_iras.each do |acct|
          break if remaining <= 0
          pulled = [remaining, acct.balance].min
          dest = household.roth_iras.find { |r| r.owner == acct.owner }
          next unless dest
          
          result = acct.convert_to_roth(pulled)
          if result[:converted] > 0
            # A conversion is a specific type of financial event.
            conv_event = FinancialEvent::RothConversion.new(
              year: tax_year.year,
              source_account: acct,
              destination_account: dest,
              amount: result[:converted]
            )
            events << conv_event
            dest.deposit(conv_event.amount) # Ensure the Roth account balance is updated.
            remaining -= result[:converted]
          end
        end
        events
      end
    end

    # The baseline strategy: no conversions, just meet spending needs.
    class NoConversion < Base
      def name; 'Do Nothing'; end
      def key; 'do_nothing'; end

      def plan_discretionary_events(household:, tax_year:, base_taxable_income:, spending_need:, ss_total: 0.0, provisional_income_before_strategy: 0.0, standard_deduction: 0.0)
        return [] if spending_need <= 0
        allocate_spending_gap(
          need: spending_need,
          household: household,
          tax_year: tax_year,
          withdrawal_hierarchy: household.withdrawal_hierarchy
        )
      end
    end

    # A "tax-aware" strategy that fills tax bracket headroom, intelligently
    # accounting for the non-linear impact of Social Security taxation and the standard deduction.
    class BracketFill < Base
      attr_reader :ceiling, :cushion_ratio

      def initialize(ceiling:, cushion_ratio: 0.05)
        @ceiling = ceiling.to_f
        @cushion_ratio = cushion_ratio.to_f
      end
      
      def name; 'Fill to Top of Bracket'; end
      def key; 'fill_to_top_of_bracket'; end

      def plan_discretionary_events(household:, tax_year:, base_taxable_income:, spending_need:, ss_total: 0.0, provisional_income_before_strategy: 0.0, standard_deduction: 0.0)
        events = []
        
        # Step 1: Fulfill Spending Needs first, as withdrawals may be taxable.
        if spending_need > 0
          spending_events = allocate_spending_gap(
            need: spending_need, household: household, tax_year: tax_year,
            withdrawal_hierarchy: household.withdrawal_hierarchy
          )
          events.concat(spending_events)
        end
        
        # Step 2: Calculate income after essential spending, and then determine conversion amount.
        taxable_from_spending = events.sum(&:taxable_amount)
        current_taxable_income = base_taxable_income + taxable_from_spending
        
        current_provisional_income = provisional_income_before_strategy + taxable_from_spending

        target_headroom = calculate_headroom_algebraically(
          provisional_income: current_provisional_income,
          ss_total: ss_total,
          tax_year: tax_year,
          filing_status: household.filing_status,
          standard_deduction: standard_deduction,
          base_taxable_income: current_taxable_income
        )

        if target_headroom > 0
          conversion_with_cushion = target_headroom * (1 - @cushion_ratio)
          available = household.traditional_iras.sum(&:balance)
          conversion_amount = [conversion_with_cushion, available].min.round(2)
          
          events.concat(perform_roth_conversion(conversion_amount, household, tax_year)) if conversion_amount > 0
        end

        events
      end

      private

      def taxable_amount_from_events(events)
        events.sum { |e| e.taxable_ordinary + e.taxable_capital_gains }
      end
      
      def calculate_headroom_algebraically(provisional_income:, ss_total:, tax_year:, filing_status:, standard_deduction:, base_taxable_income:)
        target_income = @ceiling
        
        headroom = target_income - base_taxable_income
        return headroom if ss_total.zero?
        
        taxable_ss = taxable_social_security(ss_total, other_income: provisional_income + headroom, tax_year: tax_year, filing_status: filing_status)
        
        target_income - (base_taxable_income + taxable_ss)
      end

      def taxable_social_security(ss_total, other_income: 0.0, tax_year:, filing_status:)
        thresholds = tax_year.social_security_taxability_thresholds(filing_status)
        provisional = other_income + (ss_total * 0.5);
        return 0.0 if provisional <= thresholds['phase1_start']
        if provisional <= thresholds['phase2_start']
          (provisional - thresholds['phase1_start']) * 0.5
        else
          base = (thresholds['phase2_start'] - thresholds['phase1_start']) * 0.5
          excess = (provisional - thresholds['phase2_start']) * 0.85
          [base + excess, ss_total * 0.85].min
        end
      end
    end
  end
end
