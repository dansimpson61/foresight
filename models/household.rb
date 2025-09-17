# frozen_string_literal: true

module Foresight
  class Household
    attr_reader :members, :filing_status, :state, :target_spending_after_tax, :desired_tax_bracket_ceiling,
                :accounts, :income_sources

    def initialize(members:, filing_status: 'MFJ', state: 'NY', target_spending_after_tax:, desired_tax_bracket_ceiling:, accounts: [], income_sources: [])
      @members = members
      @filing_status = filing_status
      @state = state
      @target_spending_after_tax = target_spending_after_tax
      @desired_tax_bracket_ceiling = desired_tax_bracket_ceiling
      @accounts = accounts
      @income_sources = income_sources
    end

    def pensions
      income_sources.select { |s| s.is_a?(Pension) }
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
      g = { traditional_ira: 0.0, roth_ira: 0.0, taxable: 0.0 }.merge(growth_assumptions.transform_keys(&:to_sym))
      traditional_iras.each { |a| a.grow(g[:traditional_ira]) }
      roth_iras.each { |a| a.grow(g[:roth_ira]) }
      taxable_brokerage_accounts.each { |a| a.grow(g[:taxable]) }
      # Adjust spending for inflation if provided
      @target_spending_after_tax *= (1 + inflation_rate) if inflation_rate.to_f != 0.0
    end
  end
end
