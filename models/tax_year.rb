# frozen_string_literal: true

require 'yaml'

module Foresight
  class TaxYear
    attr_reader :year, :brackets

    def initialize(year:)
      @year = year.to_i
      # Simplified: using 2023 brackets for all years
      @brackets = YAML.load_file('./config/tax_brackets.yml')
    end

    def standard_deduction
      @brackets['standard_deduction_mfj_2023']
    end

    def calculate(taxable_income:, capital_gains: 0.0)
      # Simplified federal tax calculation
      tax = 0.0
      remaining_income = taxable_income

      brackets['mfj_2023']['ordinary'].reverse_each do |bracket|
        next if remaining_income <= bracket['income']

        taxable_at_this_rate = remaining_income - bracket['income']
        tax += taxable_at_this_rate * bracket['rate']
        remaining_income = bracket['income']
      end

      # Simplified capital gains tax
      tax += capital_gains * 0.15 # Assume 15% flat capital gains tax

      { federal_tax: tax, state_tax: taxable_income * 0.04 } # Simplified 4% state tax
    end

    def irmaa_part_b_surcharge(magi: 0.0)
      magi ||= 0.0 # Ensure magi is not nil
      found_tier = brackets['mfj_2023']['irmaa_part_b'].find { |tier| magi <= tier['income_threshold'] }
      found_tier ? found_tier['surcharge_per_person'] : brackets['mfj_2023']['irmaa_part_b'].last['surcharge_per_person']
    end

    def irmaa_part_d_surcharge(magi: 0.0)
      magi ||= 0.0 # Ensure magi is not nil
      found_tier = brackets['mfj_2023']['irmaa_part_d'].find { |tier| magi <= tier['income_threshold'] }
      found_tier ? found_tier['surcharge_per_person'] : brackets['mfj_2023']['irmaa_part_d'].last['surcharge_per_person']
    end
  end
end
