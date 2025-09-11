#!/usr/bin/env ruby
# frozen_string_literal: true

module Foresight
  module ConversionStrategies
    # Interface: implement #name and #conversion_amount(household:, tax_year:, base_taxable_income:)
    class Base
      def name
        self.class.name.split('::').last
      end

      def conversion_amount(household:, tax_year:, base_taxable_income:)
        raise NotImplementedError
      end
    end

    # Always perform zero conversion
    class NoConversion < Base
      def conversion_amount(household:, tax_year:, base_taxable_income:)
        0.0
      end
    end

    # Fill ordinary bracket headroom up to desired ceiling with optional cushion
    class BracketFill < Base
      def initialize(cushion_ratio: 0.05)
        @cushion_ratio = cushion_ratio
      end

      def conversion_amount(household:, tax_year:, base_taxable_income:)
        ceiling = household.desired_tax_bracket_ceiling
        headroom = ceiling - base_taxable_income
        return 0.0 if headroom <= 0
        available = household.traditional_iras.sum(&:balance)
        target = headroom * (1 - @cushion_ratio)
        [target, available].min.round(2)
      end
    end

    # Placeholder for future strategies (e.g., IRMAA Guardrail, Future RMD Pressure)
  end
end
