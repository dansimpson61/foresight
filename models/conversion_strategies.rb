#!/usr/bin/env ruby
# frozen_string_literal: true

module Foresight
  module ConversionStrategies
    class Base
      def name
        self.class.name.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').downcase
      end

      # The key should be a simple, machine-readable identifier.
      def key
        name
      end
    end

    class NoConversion < Base
      def name
        'Do Nothing' # A human-readable name
      end

      def key
        'do_nothing' # The machine-readable key
      end

      def conversion_amount(household:, tax_year:, base_taxable_income:)
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
        'Fill to Top of Bracket' # A human-readable name
      end

      def key
        'fill_to_top_of_bracket' # The machine-readable key
      end

      def conversion_amount(household:, tax_year:, base_taxable_income:)
        headroom = @ceiling - base_taxable_income
        return 0.0 if headroom <= 0
        
        available = household.traditional_iras.sum(&:balance)
        target = headroom * (1 - @cushion_ratio)
        [target, available].min.round(2)
      end
    end
  end
end
