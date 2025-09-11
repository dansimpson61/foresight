# frozen_string_literal: true

module Foresight
  class Person
  # SECURE 2.0: Age 73 currently; age 75 for those born 1960 or later (effective 2033)
  RMD_AGE_CURRENT = 73
  RMD_AGE_FUTURE = 75

    attr_reader :name, :date_of_birth

    def initialize(name:, date_of_birth:)
      @name = name
      @date_of_birth = Date.parse(date_of_birth.to_s)
    end

    def age_in(year)
      year - @date_of_birth.year - before_birthday?(year)
    end

    def rmd_start_age
      @rmd_start_age ||= (date_of_birth.year >= 1960 ? RMD_AGE_FUTURE : RMD_AGE_CURRENT)
    end

    def rmd_eligible_in?(year)
      age_in(year) >= rmd_start_age
    end

    private

    def before_birthday?(year)
      birthday = Date.new(year, @date_of_birth.month, @date_of_birth.day)
      Date.today < birthday ? 1 : 0
    end
  end
end
