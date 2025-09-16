# frozen_string_literal: true

require_relative './money'

module Foresight
  class TaxYear
    attr_reader :year, :federal_brackets, :standard_deduction, :ltcg_brackets

    # Ordinary income tax brackets (MFJ, 2025 - simplified/truncated)
    ORDINARY_BRACKETS_2025_MFJ = [
      [Money.new(0), 0.10],
      [Money.new(22_000), 0.12],
      [Money.new(94_300), 0.22],
      [Money.new(201_050), 0.24]
    ].freeze # truncated

    # Long-term capital gains brackets (MFJ, 2025 - simplified)
    LTCG_BRACKETS_2025_MFJ = [
      [Money.new(0), 0.0],
      [Money.new(94_050), 0.15],
      [Money.new(583_750), 0.20]
    ].freeze

    # Backward-compatibility aliases (internal use only)
    MFJ_2025_ORDINARY = ORDINARY_BRACKETS_2025_MFJ
    MFJ_2025_LTCG = LTCG_BRACKETS_2025_MFJ

    def initialize(year:, federal_brackets: ORDINARY_BRACKETS_2025_MFJ, standard_deduction: 29_200, ltcg_brackets: LTCG_BRACKETS_2025_MFJ)
      @year = year
      @federal_brackets = federal_brackets
      @standard_deduction = Money.new(standard_deduction)
      @ltcg_brackets = ltcg_brackets
    end

    # Simplified 2025 IRMAA thresholds for MFJ (MAGI) and monthly Part B surcharges (approx; illustrative)
    IRMAA_BRACKETS_2025_MFJ = [
      { limit: Money.new(206000), part_b_monthly: Money.new(0) },
      { limit: Money.new(258000), part_b_monthly: Money.new(69.90) },
      { limit: Money.new(322000), part_b_monthly: Money.new(174.70) },
      { limit: Money.new(386000), part_b_monthly: Money.new(279.50) },
      { limit: Money.new(750000), part_b_monthly: Money.new(384.30) },
      { limit: Money.new(Float::INFINITY), part_b_monthly: Money.new(419.30) }
    ].freeze

    # Backward-compatibility alias
    IRMAA_THRESHOLDS_MFJ_2025 = IRMAA_BRACKETS_2025_MFJ

    # Determine annualized IRMAA surcharge (Part B only) given MAGI
    def irmaa_part_b_surcharge(magi)
      bracket = IRMAA_BRACKETS_2025_MFJ.find { |h| magi.amount <= h[:limit].amount }
      bracket[:part_b_monthly] * 12
    end

    def tax_on_ordinary(taxable_income)
      compute_bracket_tax(taxable_income, @federal_brackets)
    end

    def tax_on_ltcg(ltcg_income, ordinary_taxable_income: Money.new(0))
      # Simplified stacking: LTCG sits on top of ordinary
      remaining = ltcg_income
      tax = Money.new(0)
      prior_layer_ceiling = ordinary_taxable_income
      @ltcg_brackets.each_with_index do |(threshold, rate), idx|
        next_threshold = @ltcg_brackets[idx + 1]&.first || Money.new(Float::INFINITY)
        band_start = [threshold.amount, prior_layer_ceiling.amount].max
        break if remaining.amount <= 0
        band_space = next_threshold - band_start
        slice = [remaining.amount, band_space.amount].min
        tax += Money.new(slice) * rate if slice.positive?
        remaining -= slice
      end
      tax
    end

    # --- NY State (simplified) ---
    NY_BRACKETS_2025_MFJ = [
      [Money.new(0), 0.04],
      [Money.new(17150), 0.045],
      [Money.new(23600), 0.0525],
      [Money.new(27900), 0.0585],
      [Money.new(161550), 0.0625],
      [Money.new(323200), 0.0685],
      [Money.new(2155350), 0.0965],
      [Money.new(5000000), 0.103],
      [Money.new(25000000), 0.109]
    ].freeze # approximate breakpoints/rates

    # Backward-compatibility alias
    NY_MFJ_2025 = NY_BRACKETS_2025_MFJ

    def ny_standard_deduction(filing_status)
      Money.new(filing_status == 'MFJ' ? 16050 : 8000)
    end

    def ny_tax_on_income(taxable_income, filing_status: 'MFJ')
      brackets = NY_BRACKETS_2025_MFJ
      compute_bracket_tax(taxable_income, brackets)
    end

    private

    def compute_bracket_tax(amount, brackets)
      tax = Money.new(0)
      brackets.each_with_index do |(threshold, rate), idx|
        next_threshold = brackets[idx + 1]&.first || Money.new(Float::INFINITY)
        band_width = next_threshold - threshold
        break if amount.amount <= threshold.amount
        slice = [amount.amount - threshold.amount, band_width.amount].min
        tax += Money.new(slice) * rate
      end
      tax
    end
  end
end
