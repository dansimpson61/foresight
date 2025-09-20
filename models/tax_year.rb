# frozen_string_literal: true

require 'yaml'

module Foresight
  class TaxYear
    attr_reader :year, :brackets

    def initialize(year:)
      @year = year.to_i
      @brackets = YAML.load_file('./config/tax_brackets.yml')
    end

    def standard_deduction(filing_status)
      key = "standard_deduction_#{filing_status}_2023"
      @brackets.fetch(key)
    end
    
    def brackets_for_status(filing_status)
      status_key = "#{filing_status}_2023"
      {
        standard_deduction: standard_deduction(filing_status),
        brackets: @brackets[status_key]['ordinary'].map do |bracket|
          { 'rate' => bracket['rate'], 'ceiling' => bracket['income'] }
        end
      }
    end

    def calculate(filing_status:, taxable_income:, capital_gains: 0.0)
      status_key = "#{filing_status}_2023"
      tax = 0.0
      remaining_income = taxable_income

      # Calculate ordinary income tax
      @brackets[status_key]['ordinary'].reverse_each do |bracket|
        next if remaining_income <= bracket['income']
        taxable_at_this_rate = remaining_income - bracket['income']
        tax += taxable_at_this_rate * bracket['rate']
        remaining_income = bracket['income']
      end

      # Add capital gains tax
      capital_gains_tax = calculate_capital_gains_tax(filing_status: filing_status, taxable_income: taxable_income, capital_gains: capital_gains)
      tax += capital_gains_tax
      
      # Simplified state tax
      state_tax = taxable_income * 0.04 

      { federal_tax: tax, state_tax: state_tax, capital_gains_tax: capital_gains_tax }
    end

    def calculate_capital_gains_tax(filing_status:, taxable_income:, capital_gains:)
      return 0.0 if capital_gains <= 0

      status_key = "#{filing_status}_2023"
      cg_brackets = @brackets[status_key]['capital_gains']
      
      tax = 0.0
      remaining_gains = capital_gains
      
      cg_brackets.reverse_each do |bracket|
          break if remaining_gains <= 0
          
          # The income threshold for capital gains includes ordinary income
          threshold = bracket['income']
          
          taxable_income_plus_gains = taxable_income + remaining_gains

          if taxable_income_plus_gains > threshold
            taxable_in_this_bracket = taxable_income_plus_gains - threshold
            taxable_in_this_bracket = [taxable_in_this_bracket, remaining_gains].min

            tax += taxable_in_this_bracket * bracket['rate']
            remaining_gains -= taxable_in_this_bracket
          end
      end
      
      tax
  end
    
    def social_security_taxability_thresholds(filing_status)
        status_key = "#{filing_status}_2023"
        @brackets[status_key]['social_security_provisional_income']
    end

    def irmaa_part_b_surcharge(magi: 0.0, status:)
      magi ||= 0.0
      status_key = "#{status}_2023"
      find_irmaa_surcharge(magi, @brackets[status_key]['irmaa_part_b'])
    end

    def irmaa_part_d_surcharge(magi: 0.0, status:)
      magi ||= 0.0
      status_key = "#{status}_2023"
      find_irmaa_surcharge(magi, @brackets[status_key]['irmaa_part_d'])
    end

    private

    def find_irmaa_surcharge(magi, tiers)
      # Tiers are ordered from lowest to highest income threshold in the YAML
      found_tier = tiers.reverse.find { |tier| magi > tier['income_threshold'] }
      found_tier ? found_tier['surcharge_per_person'] * 2 : 0.0 # Multiply by 2 for household
    end
  end
end
