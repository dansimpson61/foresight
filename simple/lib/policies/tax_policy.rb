# TaxPolicy: pure helpers for tax calculations
# Contract:
# - calculate_taxes(ordinary_income, capital_gains, tax_brackets) -> { federal:, capital_gains:, total: }
# - taxable_social_security(provisional_income, ss_total, tax_brackets) -> numeric
class TaxPolicy
  class << self
    def calculate_taxes(ordinary_income, capital_gains, tax_brackets)
      brackets = tax_brackets[:mfj]
      deduction = tax_brackets[:standard_deduction][:mfj]
      taxable_ord_after_deduction = [ordinary_income - deduction, 0].max

      ord_tax = 0.0
      remaining_ord = taxable_ord_after_deduction
      brackets[:ordinary].reverse_each do |bracket|
        next if remaining_ord <= bracket[:income]
        taxable_at_this_rate = remaining_ord - bracket[:income]
        ord_tax += taxable_at_this_rate * bracket[:rate]
        remaining_ord = bracket[:income]
      end

      cg_tax = 0.0
      if taxable_ord_after_deduction > brackets[:capital_gains][1][:income]
        cg_tax = capital_gains * brackets[:capital_gains][1][:rate]
      elsif taxable_ord_after_deduction > brackets[:capital_gains][0][:income]
        cg_tax = capital_gains * 0.15
      end

      total = ord_tax + cg_tax
      { federal: ord_tax, capital_gains: cg_tax, total: total }
    end

    def taxable_social_security(provisional_income, ss_total, tax_brackets)
      return 0.0 if ss_total <= 0
      thresholds = tax_brackets[:mfj][:social_security_provisional_income]
      provisional = provisional_income + (ss_total * 0.5)
      return 0.0 if provisional <= thresholds[:phase1_start]

      if provisional <= thresholds[:phase2_start]
        return (provisional - thresholds[:phase1_start]) * 0.5
      end

      phase1_taxable = (thresholds[:phase2_start] - thresholds[:phase1_start]) * 0.5
      phase2_taxable = (provisional - thresholds[:phase2_start]) * 0.85
      [phase1_taxable + phase2_taxable, ss_total * 0.85].min
    end
  end
end
