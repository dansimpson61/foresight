module Foresight
  module Simple
    module Decisions
      # FillToBracketDecision is a pure helper that proposes a Roth conversion amount
      # such that taxable ordinary income is filled up to (but not exceeding) a target
      # bracket ceiling, considering RMDs, taxable withdrawals for spending, and the
      # taxable portion of Social Security.
      #
      # Contract (inputs):
      # - rmd: Numeric
      # - ss_benefit: Numeric (annual Social Security received)
      # - spending_withdrawals: Array of events with keys :taxable_ordinary
      # - tax_brackets: Hash of bracket data used by TaxPolicy
      # - accounts: Array of account objects (TraditionalIRA/RothIRA/TaxableAccount)
      # - ceiling: Numeric target for taxable ordinary income ceiling
      #
      # Output:
      # - Numeric conversion amount (>= 0)
      class FillToBracketDecision
        def self.propose_conversion_amount(rmd:, ss_benefit:, spending_withdrawals:, tax_brackets:, accounts:, ceiling:)
          taxable_ord_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_ordinary] }
          provisional_income_before_conversion = rmd + taxable_ord_from_withdrawals
          taxable_ss_before_conversion = TaxPolicy.taxable_social_security(provisional_income_before_conversion, ss_benefit, tax_brackets)
          taxable_income_before_conversion = rmd + taxable_ss_before_conversion + taxable_ord_from_withdrawals

          headroom = ceiling - taxable_income_before_conversion
          return 0 if headroom <= 0

          total_trad_balance = accounts.select { |a| a.is_a?(TraditionalIRA) }.sum(&:balance)
          return 0 if total_trad_balance <= 0

          [headroom, total_trad_balance].min
        end
      end
    end
  end
end
