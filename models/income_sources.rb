# frozen_string_literal: true

# Base class and specific income source models
module Foresight
  class IncomeSource
    attr_reader :recipient

    def initialize(recipient:)
      @recipient = recipient
    end
  end

  class Salary < IncomeSource
    attr_reader :annual_gross

    def initialize(recipient:, annual_gross: 0.0)
      super(recipient: recipient)
      @annual_gross = annual_gross.to_f
    end
  end

  class Pension < IncomeSource
    attr_reader :annual_gross

    def initialize(recipient:, annual_gross: 0.0)
      super(recipient: recipient)
      @annual_gross = annual_gross.to_f
    end

    def taxable_amount(_state:, recipient_age:)
      # NY exclusion simplified: up to 20k if age >= 59.5
      return @annual_gross if recipient_age < 60
      [@annual_gross - 20_000, 0.0].max
    end
  end

  class SocialSecurityBenefit < IncomeSource
    attr_reader :pia_annual, :claiming_age

    def initialize(recipient:, pia_annual:, claiming_age:)
      super(recipient: recipient)
      @pia_annual = pia_annual.to_f
      @claiming_age = claiming_age.to_i
    end

    def annual_benefit_for(year)
      age_at_year = recipient.age_in(year)
      return 0.0 if age_at_year < @claiming_age

      factor = claiming_adjustment_factor
      @pia_annual * factor
    end

    private

    def claiming_adjustment_factor
      fra_years = full_retirement_age_years(recipient.date_of_birth.year)
      if @claiming_age < fra_years
        months_early = ((fra_years - @claiming_age) * 12).round
        early_reduction_factor(months_early)
      elsif @claiming_age > fra_years
        months_delayed = ((@claiming_age - fra_years) * 12).round
        delayed_credit_factor(months_delayed)
      else
        1.0
      end
    end

    def early_reduction_factor(months_early)
      first_phase = [months_early, 36].min
      second_phase = [months_early - 36, 0].max
      reduction = first_phase * (5.0 / 9.0 / 100.0) + second_phase * (5.0 / 12.0 / 100.0)
      (1.0 - reduction).clamp(0.0, 1.0)
    end

    def delayed_credit_factor(months_delayed)
      fra_years = full_retirement_age_years(recipient.date_of_birth.year)
      capped_months = [months_delayed, (70 - fra_years) * 12].min
      credit = capped_months * (2.0 / 3.0 / 100.0)
      1.0 + credit
    end

    def full_retirement_age_years(birth_year)
      return 67 if birth_year >= 1960
      case birth_year
      when 1959 then 66 + 10.0 / 12.0
      when 1958 then 66 + 8.0 / 12.0
      when 1957 then 66 + 6.0 / 12.0
      when 1956 then 66 + 4.0 / 12.0
      when 1955 then 66 + 2.0 / 12.0
      else 66
      end
    end
  end
end
