# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/annual_planner'
require_relative '../../models/household'
require_relative '../../models/tax_year'
require_relative '../../models/conversion_strategies'
require_relative '../../models/financial_event'

RSpec.describe Foresight::AnnualPlanner do
  let(:person1) { Foresight::Person.new(name: 'John', date_of_birth: '1960-01-01') }
  let(:person2) { Foresight::Person.new(name: 'Jane', date_of_birth: '1962-01-01') }
  let(:tax_year) { Foresight::TaxYear.new(year: 2027) }

  describe '#generate_strategy' do
    context 'with NoConversion strategy' do
      it 'follows the standard withdrawal hierarchy' do
        household = Foresight::Household.new(
          members: [person1, person2], filing_status: :mfj, state: 'NY',
          accounts: [ Foresight::TaxableBrokerage.new(owners: [person1], balance: 100_000, cost_basis_fraction: 0.5) ],
          income_sources: [], annual_expenses: 50_000, emergency_fund_floor: 0,
          withdrawal_hierarchy: [:taxable]
        )
        planner = described_class.new(household: household, tax_year: tax_year)
        strategy = Foresight::ConversionStrategies::NoConversion.new
        
        result = planner.generate_strategy(strategy)
        withdrawal = result.financial_events.find { |e| e.is_a?(Foresight::FinancialEvent::SpendingWithdrawal) }
        
        expect(withdrawal.source_account).to be_a(Foresight::TaxableBrokerage)
        expect(result.taxable_income_breakdown[:capital_gains]).to be > 0
      end
    end

    context 'with BracketFill strategy' do
      let(:bracket_fill_household) do
        Foresight::Household.new(
          members: [person1, person2], filing_status: :mfj, state: 'NY',
          accounts: [
            Foresight::TraditionalIRA.new(owner: person1, balance: 500_000),
            Foresight::RothIRA.new(owner: person1, balance: 500_000)
          ],
          income_sources: [], annual_expenses: 100_000, emergency_fund_floor: 0,
          withdrawal_hierarchy: [:traditional, :roth]
        )
      end
      let(:bracket_fill_planner) { described_class.new(household: bracket_fill_household, tax_year: tax_year) }

      it 'correctly blends spending withdrawals and Roth conversions to hit the bracket ceiling' do
        target_ceiling = 89_450.0 # Top of 12% MFJ bracket for 2023
        strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: target_ceiling, cushion_ratio: 0.0)
        
        result = bracket_fill_planner.generate_strategy(strategy)
        
        total_taxable_income = result.taxable_income_breakdown.slice(
          :spending_withdrawals_ordinary, :roth_conversions, :capital_gains
        ).values.sum

        expect(total_taxable_income).to be_within(1.0).of(target_ceiling)
        
        # Verify that the spending need was met from a combination of Traditional and Roth.
        total_withdrawals = result.financial_events.select { |e| e.is_a?(Foresight::FinancialEvent::SpendingWithdrawal) }.sum(&:amount_withdrawn)
        expect(total_withdrawals).to be >= 100_000
        
        expect(result.financial_events.any? { |e| e.source_account.is_a?(Foresight::TraditionalIRA) }).to be true
        expect(result.financial_events.any? { |e| e.source_account.is_a?(Foresight::RothIRA) }).to be true
      end
    end
  end
end
