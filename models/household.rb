# frozen_string_literal: true

module Foresight
  class Household
    attr_reader :members, :filing_status, :state, :accounts, :income_sources,
                :annual_expenses, :emergency_fund_floor, :withdrawal_hierarchy

    # Note: desired_tax_bracket_ceiling is now part of the strategy, not the household.
    def initialize(members:, filing_status:, state:, accounts:, income_sources:,
                   annual_expenses:, emergency_fund_floor:, withdrawal_hierarchy:)
      @members = members
      @filing_status = filing_status.to_sym
      @state = state
      @accounts = accounts
      @income_sources = income_sources
      @annual_expenses = annual_expenses.to_f
      @emergency_fund_floor = emergency_fund_floor.to_f
      @withdrawal_hierarchy = withdrawal_hierarchy
    end

    def cash_accounts
      accounts.select { |a| a.is_a?(Cash) }
    end

    def pensions
      income_sources.select { |s| s.is_a?(Pension) }
    end
    
    def salaries
      income_sources.select { |s| s.is_a?(Salary) }
    end

    def social_security_benefits
      income_sources.select { |s| s.is_a?(SocialSecurityBenefit) }
    end

    def traditional_iras
      accounts.select { |a| a.is_a?(TraditionalIRA) }
    end

    def roth_iras
      accounts.select { |a| a.is_a?(RothIRA) }
    end

    def taxable_brokerage_accounts
      accounts.select { |a| a.is_a?(TaxableBrokerage) }
    end

    # Encapsulated asset growth and spending inflation
    def grow_assets(growth_assumptions: {}, inflation_rate: 0.0)
      g = { traditional_ira: 0.0, roth_ira: 0.0, taxable: 0.0, cash: 0.0 }.merge(growth_assumptions.transform_keys(&:to_sym))
      traditional_iras.each { |a| a.grow(g[:traditional_ira]) }
      roth_iras.each { |a| a.grow(g[:roth_ira]) }
      taxable_brokerage_accounts.each { |a| a.grow(g[:taxable]) }
      cash_accounts.each { |a| a.grow(g[:cash]) }

      # Adjust spending for inflation if provided
      @annual_expenses *= (1 + inflation_rate) if inflation_rate.to_f != 0.0
    end
  end
end
