#!/usr/bin/env ruby
# frozen_string_literal: true

module Foresight
  module ConversionStrategies
    class Base
      def name
        # A human-readable name for display purposes.
        self.class.name.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').capitalize
      end

      def key
        # A machine-readable key for use in APIs and hashes.
        name.downcase
      end
    end

    class NoConversion < Base
      def name
        'Do Nothing'
      end

      def key
        'do_nothing'
      end

      def conversion_amount(household:, tax_year:, base_taxable_income:)
        puts "[STRATEGY_STEP] NoConversion: Executing. Always returns 0."
        0.0
      end
    end

    class BracketFill < Base
      attr_reader :ceiling, :cushion_ratio

      def initialize(ceiling:, cushion_ratio: 0.05)
        @ceiling = ceiling.to_f
        @cushion_ratio = cushion_ratio.to_f
      end
      
      def name
        'Fill to Top of Bracket'
      end

      def key
        'fill_to_top_of_bracket'
      end

      def conversion_amount(household:, tax_year:, base_taxable_income:)
        puts "[STRATEGY_STEP] BracketFill: Executing. Ceiling: #{@ceiling}, Base Income: #{base_taxable_income}."
        
        # We need to account for the standard deduction, which the planner does not do beforehand.
        deduction = tax_year.standard_deduction(household.filing_status)
        taxable_income_after_deduction = [base_taxable_income - deduction, 0.0].max
        
        headroom = @ceiling - taxable_income_after_deduction
        
        if headroom <= 0
          puts "[STRATEGY_STEP] BracketFill: No headroom. Returning 0."
          return 0.0
        end
        
        available = household.traditional_iras.sum(&:balance)
        target = headroom * (1 - @cushion_ratio)
        result = [target, available].min.round(2)
        puts "[STRATEGY_STEP] BracketFill: Calculated conversion amount of #{result}."
        result
      end
    end
  end
end
