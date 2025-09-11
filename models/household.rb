# frozen_string_literal: true

module Foresight
  class Household
    attr_reader :members, :filing_status, :state, :target_spending_after_tax, :desired_tax_bracket_ceiling,
                :accounts, :income_sources

    def initialize(members:, filing_status: 'MFJ', state: 'NY', target_spending_after_tax:, desired_tax_bracket_ceiling:, accounts: [], income_sources: [])
      @members = members
      @filing_status = filing_status
      @state = state
      @target_spending_after_tax = target_spending_after_tax.to_f
      @desired_tax_bracket_ceiling = desired_tax_bracket_ceiling.to_f
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
  end
end
