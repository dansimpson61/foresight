# frozen_string_literal: true

require_relative './money'

module Foresight
  class IncomeSource
    attr_reader :recipient

    def initialize(recipient:)
      @recipient = recipient
    end
  end

  class Pension < IncomeSource
    attr_reader :annual_gross

    def initialize(recipient:, annual_gross: 0.0)
      super(recipient: recipient)
      @annual_gross = Money.new(annual_gross)
    end

    def taxable_amount(_state:, recipient_age:)
      # NY exclusion simplified: up to 20k if age >= 59.5
      if recipient_age >= 60
        [@annual_gross - 20_000, Money.new(0)].max
      else
        @annual_gross
      end
    end
  end

  class SocialSecurityBenefit < IncomeSource
    attr_reader :start_year, :cola_rate

    def initialize(recipient:, start_year:, annual_benefit: nil, pia_annual: nil, cola_rate: 0.0)
      super(recipient: recipient)
      @start_year = start_year.to_i
      @cola_rate = cola_rate.to_f
      @given_claimed_amount = annual_benefit && Money.new(annual_benefit)
      @pia_annual = pia_annual && Money.new(pia_annual)
      raise ArgumentError, 'Provide annual_benefit or pia_annual' if @given_claimed_amount.nil? && @pia_annual.nil?
    end

    def annual_benefit_for(year)
      return Money.new(0) if year < @start_year
      base = claimed_amount_at_start
      years_since_start = year - @start_year
      base * ((1 + @cola_rate)**years_since_start)
    end

    private

    def claimed_amount_at_start
      return @given_claimed_amount if @given_claimed_amount
      # derive from PIA with claiming factor
      factor = claiming_adjustment_factor
      @pia_annual * factor
    end

    def claiming_adjustment_factor
      claiming_age = recipient.age_in(@start_year)
      fra_years = full_retirement_age_years(recipient.date_of_birth.year)
      if claiming_age < fra_years
        months_early = ((fra_years - claiming_age) * 12).round
        early_reduction_factor(months_early)
      elsif claiming_age > fra_years
        months_delayed = ((claiming_age - fra_years) * 12).round
        delayed_credit_factor(months_delayed)
      else
        1.0
      end
    end

    # Early reduction: first 36 months 5/9 of 1% each, remaining 5/12 of 1%
    def early_reduction_factor(months_early)
      first_phase = [months_early, 36].min
      second_phase = [months_early - 36, 0].max
      reduction = first_phase * (5.0 / 9.0 / 100.0) + second_phase * (5.0 / 12.0 / 100.0)
      (1.0 - reduction).clamp(0.0, 1.0)
    end

    # Delayed credits: 2/3 of 1% per month (≈8% per year) up to age 70
    def delayed_credit_factor(months_delayed)
      capped_months = [months_delayed, (70 - full_retirement_age_years(recipient.date_of_birth.year)) * 12].min
      credit = capped_months * (2.0 / 3.0 / 100.0)
      1.0 + credit
    end

    # For birth year 1960+ FRA = 67. Provide simplified mapping for earlier years.
    def full_retirement_age_years(birth_year)
      return 67 if birth_year >= 1960
      # Approx table for 1955-1959 (skipping precise months granularity: convert months to fraction)
      case birth_year
      when 1959 then 66 + 10.0 / 12.0
      when 1958 then 66 + 8.0 / 12.0
      when 1957 then 66 + 6.0 / 12.0
      when 1956 then 66 + 4.0 / 12.0
      when 1955 then 66 + 2.0 / 12.0
      else 66 # 1943-1954
      end
    end
  end
end
