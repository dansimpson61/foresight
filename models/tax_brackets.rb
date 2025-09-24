# frozen_string_literal: true

require 'yaml'

module Foresight
  class TaxBrackets
    def self.load
      @brackets ||= YAML.load_file('./config/tax_brackets.yml')
    end

    def self.for_year(year)
      load
      last_known_year = @brackets.keys.max
      @brackets[year] || @brackets[last_known_year]
    end
  end
end