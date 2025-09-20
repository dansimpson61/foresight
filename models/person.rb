# frozen_string_literal: true

require 'date'

module Foresight
  class Person
    attr_reader :name, :date_of_birth

    UNIFORM_LIFETIME_TABLE = {
      73 => 26.5, 74 => 25.5, 75 => 24.6, 76 => 23.7, 77 => 22.9,
      78 => 22.0, 79 => 21.2, 80 => 20.3, 81 => 19.5, 82 => 18.7,
      83 => 17.9, 84 => 17.1, 85 => 16.3, 86 => 15.5, 87 => 14.8,
      88 => 14.1, 89 => 13.4, 90 => 12.7, 91 => 12.0, 92 => 11.4
    }.freeze

    def initialize(name:, date_of_birth:)
      @name = name
      @date_of_birth = date_of_birth.is_a?(Date) ? date_of_birth : Date.parse(date_of_birth)
    end

    def age_in(year)
      year - @date_of_birth.year
    end

    def rmd_eligible_in?(year)
      age_in(year) >= rmd_start_age
    end
    
    def rmd_start_age
      birth_year = @date_of_birth.year
      # Ignoring the 70.5 rule for simplicity as it applies to past years.
      # Focusing on SECURE Act 1.0 and 2.0 rules.
      if birth_year <= 1950
        72
      elsif birth_year <= 1959
        73
      else # 1960 and later
        75
      end
    end

    def rmd_divisor_for(year)
      age = age_in(year)
      return nil unless rmd_eligible_in?(year)
      UNIFORM_LIFETIME_TABLE[age]
    end
  end
end
