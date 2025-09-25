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

  # Stub the data loading to make tests self-contained and fast.
  before do
    allow(Foresight::TaxBrackets).to receive(:for_year).with(anything).and_return({
      'standard_deduction' => { 'mfj' => 29200 },
      'mfj' => {
        'ordinary' => [
          { 'rate' => 0.10, 'income' => 0 },
          { 'rate' => 0.12, 'income' => 23200 },
          { 'rate' => 0.22, 'income' => 94300 },
          { 'rate' => 0.24, 'income' => 201050 }
        ],
        'capital_gains' => [
          { 'rate' => 0.0, 'income' => 0 },
          { 'rate' => 0.15, 'income' => 94050 },
          { 'rate' => 0.20, 'income' => 583750 }
        ],
        'social_security_provisional_income' => {
            'phase1_start' => 32000,
            'phase2_start' => 44000
        }
      }
    })
  end

  describe '#generate_strategy' do
    context 'with NoConversion strategy' do
      it 'follows the standard withdrawal hierarchy' do
        household = Foresight::Household.new(
          members: [person1, person2], filing_status: :mfj, state: 'NY',
          accounts: [ Foresight::TaxableBrokerage.new(owners: [person1, person2], balance: 100_000, cost_basis_fraction: 0.5) ],
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
          income_sources: [], annual_expenses: 50_000, emergency_fund_floor: 0,
          withdrawal_hierarchy: [:traditional, :roth]
        )
      end
      let(:bracket_fill_planner) { described_class.new(household: bracket_fill_household, tax_year: tax_year) }

      it 'correctly blends spending withdrawals and Roth conversions to hit the bracket ceiling' do
        bracket_ceiling = 94300.0 # Top of 22% MFJ bracket
        strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: bracket_ceiling, cushion_ratio: 0.0)
        
        result = bracket_fill_planner.generate_strategy(strategy)
        
        total_taxable_income = result.taxable_income_breakdown.slice(
          :spending_withdrawals_ordinary, :roth_conversions, :capital_gains
        ).values.sum
        
        # The total taxable income should equal the bracket ceiling.
        # The model internally accounts for the standard deduction to calculate the necessary conversion.
        expect(total_taxable_income).to be_within(1.0).of(bracket_ceiling)
        
        # Verify that the spending need was met
        total_withdrawals = result.financial_events.select { |e| e.is_a?(Foresight::FinancialEvent::SpendingWithdrawal) }.sum(&:amount_withdrawn)
        expect(total_withdrawals).to be >= 50_000
      end
    end
  end
end
