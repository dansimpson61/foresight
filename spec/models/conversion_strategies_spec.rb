# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/conversion_strategies'
require_relative '../../models/household'
require_relative '../../models/tax_year'
require_relative '../../models/financial_event'

RSpec.describe Foresight::ConversionStrategies do
  let(:person1) { Foresight::Person.new(name: 'John', date_of_birth: '1970-01-01') }
  let(:person2) { Foresight::Person.new(name: 'Jane', date_of_birth: '1972-01-01') }
  let(:traditional_ira) { Foresight::TraditionalIRA.new(owner: person1, balance: 100_000) }
  let(:roth_ira) { Foresight::RothIRA.new(owner: person1, balance: 50_000) }

  let(:household) do
    Foresight::Household.new(
      members: [person1, person2],
      accounts: [traditional_ira, roth_ira],
      filing_status: :mfj,
      withdrawal_hierarchy: %i[traditional roth],
      state: 'NY',
      income_sources: [],
      annual_expenses: 60000,
      emergency_fund_floor: 20000
    )
  end
  let(:tax_year) { Foresight::TaxYear.new(year: 2023) }

  describe 'NoConversion Strategy' do
    let(:strategy) { Foresight::ConversionStrategies::NoConversion.new }

    it 'creates no RothConversion events' do
      events = strategy.plan_discretionary_events(
        household: household, tax_year: tax_year,
        base_taxable_income: 50_000, spending_need: 10_000
      )
      conversion_events = events.select { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
      expect(conversion_events).to be_empty
    end

    it 'creates only SpendingWithdrawal events' do
      events = strategy.plan_discretionary_events(
        household: household, tax_year: tax_year,
        base_taxable_income: 50_000, spending_need: 10_000
      )
      expect(events).to all(be_a(Foresight::FinancialEvent::SpendingWithdrawal))
      total_withdrawn = events.sum(&:amount_withdrawn)
      expect(total_withdrawn).to be_within(0.01).of(10_000)
    end
  end

  describe 'BracketFill Strategy' do
    let(:strategy) { Foresight::ConversionStrategies::BracketFill.new(ceiling: 89_450) } # 22% bracket for MFJ in 2023
    let(:base_taxable_income) { 50_000 }

    context 'when there is ample headroom and no spending need' do
      it 'creates a RothConversion to fill the bracket (with cushion)' do
        events = strategy.plan_discretionary_events(
          household: household, tax_year: tax_year,
          base_taxable_income: base_taxable_income, spending_need: 0
        )
        
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).not_to be_nil
        
        expected_headroom = 89_450 - base_taxable_income
        expected_conversion = expected_headroom * (1 - 0.05) # cushion
        expect(conversion.amount).to be_within(0.01).of(expected_conversion)
      end
    end

    context 'when base income is already over the ceiling' do
      it 'creates no new events' do
        events = strategy.plan_discretionary_events(
          household: household, tax_year: tax_year,
          base_taxable_income: 120_000, spending_need: 0
        )
        expect(events).to be_empty
      end
    end

    context 'when the available IRA balance is the limiting factor' do
      let(:household_low_ira) do
        Foresight::Household.new(
          members: [person1, person2],
          accounts: [
            Foresight::TraditionalIRA.new(owner: person1, balance: 10_000), # Only 10k available
            Foresight::RothIRA.new(owner: person1, balance: 50_000)
          ],
          filing_status: :mfj,
          withdrawal_hierarchy: %i[traditional roth],
          state: 'NY',
          income_sources: [],
          annual_expenses: 60000,
          emergency_fund_floor: 20000
        )
      end

      it 'converts only up to the available balance' do
        events = strategy.plan_discretionary_events(
          household: household_low_ira, tax_year: tax_year,
          base_taxable_income: base_taxable_income, spending_need: 0
        )
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion.amount).to be_within(0.01).of(10_000)
      end
    end
  end
end
