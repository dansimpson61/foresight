# frozen_string_literal: true

require 'yaml'

module Foresight
  class TaxYear
    attr_reader :year, :brackets

    def initialize(year:)
      @year = year.to_i
      @brackets = YAML.load_file('./config/tax_brackets.yml')
    end

    def calculate(filing_status:, taxable_income:, capital_gains: 0.0)
      status_key = "#{filing_status}_2023"
      tax = 0.0
      income_to_tax = taxable_income

      sorted_brackets = @brackets[status_key]['ordinary'].sort_by { |b| b['income'] }
      
      (0...sorted_brackets.size).each do |i|
        bracket = sorted_brackets[i]
        bracket_floor = bracket['income'].to_f
        bracket_rate = bracket['rate'].to_f
        bracket_ceiling = (i + 1 < sorted_brackets.size) ? sorted_brackets[i+1]['income'].to_f : Float::INFINITY

        if income_to_tax > bracket_floor
          taxable_in_bracket = [income_to_tax, bracket_ceiling].min - bracket_floor
          tax += taxable_in_bracket * bracket_rate
        end
      end

      { federal_tax: tax, state_tax: 0, capital_gains_tax: 0 }
    end
    
    def irmaa_part_b_surcharge(magi: 0.0, status:)
      magi ||= 0.0
      status_key = "#{status}_2023"
      find_irmaa_surcharge(magi, @brackets[status_key]['irmaa_part_b'])
    end

    private

    def find_irmaa_surcharge(magi, tiers)
      # Filter out non-numeric thresholds and sort from high to low
      valid_tiers = tiers.select { |t| t['income_threshold'].is_a?(Numeric) }
      sorted_tiers = valid_tiers.sort_by { |t| t['income_threshold'] }.reverse
      
      found_tier = sorted_tiers.find { |tier| magi > tier['income_threshold'].to_f }
      
      return 0.0 unless found_tier
      
      found_tier['surcharge_per_person'].to_f * 2 * 12
    end
  end
end
