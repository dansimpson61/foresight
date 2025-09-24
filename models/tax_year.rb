# frozen_string_literal: true

require 'yaml'
require_relative 'tax_brackets'

module Foresight
  class TaxYear
    attr_reader :year, :brackets

    def initialize(year:)
      @year = year.to_i
      @brackets = TaxBrackets.for_year(@year)
    end

    def standard_deduction(filing_status)
      @brackets.dig('standard_deduction', filing_status.to_s)
    end

    def brackets_for_status(filing_status)
      status_key = filing_status.to_s
      {
        standard_deduction: standard_deduction(filing_status),
        brackets: @brackets.dig(status_key, 'ordinary')&.map do |bracket|
          { 'rate' => bracket['rate'], 'ceiling' => bracket['income'] }
        end
      }
    end

    def calculate(filing_status:, taxable_income:, capital_gains: 0.0)
      status_key = filing_status.to_s
      tax = 0.0
      remaining_income = taxable_income
      ordinary_brackets = @brackets.dig(status_key, 'ordinary')

      # Calculate ordinary income tax
      ordinary_brackets.reverse_each do |bracket|
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

      status_key = filing_status.to_s
      cg_brackets = @brackets.dig(status_key, 'capital_gains')
      
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
        status_key = filing_status.to_s
        @brackets.dig(status_key, 'social_security_provisional_income')
    end

    def irmaa_part_b_surcharge(magi: 0.0, status:)
      magi ||= 0.0
      status_key = status.to_s
      find_irmaa_surcharge(magi, @brackets.dig(status_key, 'irmaa_part_b'))
    end

    def irmaa_part_d_surcharge(magi: 0.0, status:)
      magi ||= 0.0
      status_key = status.to_s
      find_irmaa_surcharge(magi, @brackets.dig(status_key, 'irmaa_part_d'))
    end

    private

    def find_irmaa_surcharge(magi, tiers)
      return 0.0 if tiers.nil?
      # Tiers are ordered from lowest to highest income threshold in the YAML
      found_tier = tiers.reverse.find { |tier| magi > tier['income_threshold'] }
      found_tier ? found_tier['surcharge_per_person'] * 2 : 0.0 # Multiply by 2 for household
    end
  end
end
