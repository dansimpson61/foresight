# frozen_string_literal: true

module Foresight
  class TaxYear
  attr_reader :year, :federal_brackets, :standard_deduction, :ltcg_brackets

    MFJ_2025_ORDINARY = [
      [0, 0.10],
      [22_000, 0.12],
      [94_300, 0.22],
      [201_050, 0.24]
    ].freeze # truncated

    MFJ_2025_LTCG = [
      [0, 0.0],
      [94_050, 0.15],
      [583_750, 0.20]
    ].freeze

    def initialize(year:, federal_brackets: MFJ_2025_ORDINARY, standard_deduction: 29_200, ltcg_brackets: MFJ_2025_LTCG)
      @year = year
      @federal_brackets = federal_brackets
      @standard_deduction = standard_deduction
      @ltcg_brackets = ltcg_brackets
    end

    # Simplified 2025 IRMAA thresholds for MFJ (MAGI) and monthly Part B surcharges (approx; illustrative)
    IRMAA_THRESHOLDS_MFJ_2025 = [
      { limit: 206000, part_b_monthly: 0 },
      { limit: 258000, part_b_monthly: 69.90 },
      { limit: 322000, part_b_monthly: 174.70 },
      { limit: 386000, part_b_monthly: 279.50 },
      { limit: 750000, part_b_monthly: 384.30 },
      { limit: Float::INFINITY, part_b_monthly: 419.30 }
    ].freeze

    # Determine annualized IRMAA surcharge (Part B only) given MAGI
    def irmaa_part_b_surcharge(magi)
      bracket = IRMAA_THRESHOLDS_MFJ_2025.find { |h| magi <= h[:limit] }
      (bracket[:part_b_monthly] * 12).round(2)
    end

    def tax_on_ordinary(taxable_income)
      compute_bracket_tax(taxable_income, @federal_brackets)
    end

    def tax_on_ltcg(ltcg_income, ordinary_taxable_income: 0)
      # Simplified stacking: LTCG sits on top of ordinary
      remaining = ltcg_income
      tax = 0.0
      prior_layer_ceiling = ordinary_taxable_income
      @ltcg_brackets.each_with_index do |(threshold, rate), idx|
        next_threshold = @ltcg_brackets[idx + 1]&.first || Float::INFINITY
        band_start = [threshold, prior_layer_ceiling].max
        break if remaining <= 0
        band_space = next_threshold - band_start
        slice = [remaining, band_space].min
        tax += slice * rate if slice.positive?
        remaining -= slice
      end
      tax
    end

    # --- NY State (simplified) ---
    NY_MFJ_2025 = [
      [0, 0.04],
      [17150, 0.045],
      [23600, 0.0525],
      [27900, 0.0585],
      [161550, 0.0625],
      [323200, 0.0685],
      [2155350, 0.0965],
      [5000000, 0.103],
      [25000000, 0.109]
    ].freeze # approximate breakpoints/rates

    def ny_standard_deduction(filing_status)
      filing_status == 'MFJ' ? 16050 : 8000
    end

    def ny_tax_on_income(taxable_income, filing_status: 'MFJ')
      brackets = NY_MFJ_2025
      compute_bracket_tax(taxable_income, brackets)
    end

    private

    def compute_bracket_tax(amount, brackets)
      tax = 0.0
      brackets.each_with_index do |(threshold, rate), idx|
        next_threshold = brackets[idx + 1]&.first || Float::INFINITY
        band_width = next_threshold - threshold
        break if amount <= threshold
        slice = [amount - threshold, band_width].min
        tax += slice * rate
      end
      tax
    end
  end
end
