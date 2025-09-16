# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../foresight'

module Foresight
  class MoneyIntegrationTest < Minitest::Test
    def setup
      @alice = Person.new(name: 'Alice', date_of_birth: Date.new(1961, 6, 15))
      @bob = Person.new(name: 'Bob', date_of_birth: Date.new(1967, 2, 10))
      @household = Household.new(
        members: [@alice, @bob],
        target_spending_after_tax: 60_000,
        desired_tax_bracket_ceiling: 94_300,
        accounts: [
          TraditionalIRA.new(owner: @alice, balance: 100_000)
        ],
        income_sources: [
          SocialSecurityBenefit.new(recipient: @alice, start_year: 2025, pia_annual: 24_000)
        ]
      )
      @tax_year = TaxYear.new(year: 2025)
    end

    def test_bracket_fill_with_money
      planner = AnnualPlanner.new(household: @household, tax_year: @tax_year)
      strategy = ConversionStrategies::BracketFill.new
      result = planner.generate_strategy(strategy)

      assert_kind_of Float, result.federal_tax
      assert result.federal_tax > 0, 'Federal tax should be greater than 0'
    end
  end
end
