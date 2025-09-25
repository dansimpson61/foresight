#!/usr/bin/env ruby
# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/conversion_strategies'
require_relative '../../models/household'
require_relative '../../models/person'
require_relative '../../models/accounts'
require_relative '../../models/tax_year'
require_relative '../../models/tax_brackets'

RSpec.describe Foresight::ConversionStrategies do
  let(:p1) { Foresight::Person.new(name: 'Person 1', date_of_birth: '1960-01-01') }
  let(:p2) { Foresight::Person.new(name: 'Person 2', date_of_birth: '1962-01-01') }
  let(:base_accounts) do
    [
      Foresight::TraditionalIRA.new(owner: p1, balance: 200_000),
      Foresight::RothIRA.new(owner: p1, balance: 50_000)
    ]
  end
  let(:household) do
    Foresight::Household.new(
      members: [p1, p2],
      filing_status: 'married_filing_jointly',
      state: 'CA',
      accounts: base_accounts,
      income_sources: [],
      annual_expenses: 60_000,
      emergency_fund_floor: 25_000,
      withdrawal_hierarchy: [:cash, :taxable, :traditional, :roth]
    )
  end
  
  # Stub the data loading to make tests self-contained and fast.
  before do
    allow(Foresight::TaxBrackets).to receive(:for_year).with(anything).and_return({
      'standard_deduction' => {
        'married_filing_jointly' => 29200
      },
      'married_filing_jointly' => {
        'ordinary' => [
          { 'rate' => 0.10, 'income' => 0 },
          { 'rate' => 0.12, 'income' => 23200 },
          { 'rate' => 0.22, 'income' => 94300 },
          { 'rate' => 0.24, 'income' => 201050 }
        ],
        'social_security_provisional_income' => {
            'phase1_start' => 32000,
            'phase2_start' => 44000
        }
      }
    })
  end

  let(:tax_year) { Foresight::TaxYear.new(year: 2024) }
  let(:standard_deduction) { tax_year.standard_deduction('married_filing_jointly') }
  let(:args) do
    {
      household: household,
      tax_year: tax_year,
      base_taxable_income: 10_000,
      spending_need: 0,
      provisional_income_before_strategy: 10_000,
      standard_deduction: standard_deduction
    }
  end

  describe 'ConditionalConversion (Base Class)' do
    context 'when Social Security benefits are claimed' do
      it 'delegates to NoConversion strategy' do
        accounts_with_cash = base_accounts + [Foresight::Cash.new(balance: 2000)]
        local_household = Foresight::Household.new(
          members: [p1, p2], filing_status: 'married_filing_jointly', state: 'CA',
          accounts: accounts_with_cash, income_sources: [], annual_expenses: 60_000,
          emergency_fund_floor: 0,
          withdrawal_hierarchy: [:cash, :taxable, :traditional, :roth]
        )
        
        strategy = described_class::ConditionalFixedAmount.new(amount: 5000)
        args[:household] = local_household
        args[:ss_total] = 30_000
        args[:spending_need] = 1000

        events = strategy.plan_discretionary_events(**args)
        expect(events.size).to eq(1)
        expect(events.first).to be_a(Foresight::FinancialEvent::SpendingWithdrawal)
        expect(events.sum(&:amount_withdrawn)).to eq(1000)
      end
    end
  end

  describe 'ConditionalBracketFill' do
    let(:strategy) { described_class::ConditionalBracketFill.new(ceiling: 94300) }

    context 'with no SS income' do
      it 'calculates a conversion to fill the bracket' do
        args[:ss_total] = 0
        events = strategy.plan_discretionary_events(**args)
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        
        expect(conversion).not_to be_nil
        
        # The code's logic is correct: headroom is based on TOTAL income, which includes the standard deduction.
        headroom = (94300 + standard_deduction) - args[:base_taxable_income]
        expected_conversion = headroom * 0.95
        
        expect(conversion.amount).to be_within(1.0).of(expected_conversion)
      end
    end

    context 'with SS income' do
      it 'does not perform a conversion' do
        args[:ss_total] = 30_000
        events = strategy.plan_discretionary_events(**args)
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).to be_nil
      end
    end
  end

  describe 'ConditionalBracketFillWithYears' do
    let(:strategy) { described_class::ConditionalBracketFillWithYears.new(ceiling: 94300, start_year: 2024, end_year: 2026) }

    context 'within the specified year range and no SS' do
      it 'performs a conversion' do
        args[:tax_year] = Foresight::TaxYear.new(year: 2025)
        args[:ss_total] = 0
        events = strategy.plan_discretionary_events(**args)
        expect(events.any? { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }).to be true
      end
    end

    context 'outside the specified year range' do
      it 'does not perform a conversion' do
        args[:tax_year] = Foresight::TaxYear.new(year: 2027)
        args[:ss_total] = 0
        events = strategy.plan_discretionary_events(**args)
        expect(events.any? { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }).to be false
      end
    end
    
    context 'within the year range but with SS income' do
      it 'does not perform a conversion' do
        args[:tax_year] = Foresight::TaxYear.new(year: 2025)
        args[:ss_total] = 35_000
        events = strategy.plan_discretionary_events(**args)
        expect(events.any? { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }).to be false
      end
    end
  end
  
  describe 'ConditionalFixedAmount' do
    let(:strategy) { described_class::ConditionalFixedAmount.new(amount: 40_000) }

    context 'with no SS income' do
      it 'converts the specified fixed amount' do
        args[:ss_total] = 0
        events = strategy.plan_discretionary_events(**args)
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).not_to be_nil
        expect(conversion.amount).to eq(40_000)
      end
      
      it 'converts only the available balance if less than the fixed amount' do
        accounts = [
          Foresight::TraditionalIRA.new(owner: p1, balance: 30_000),
          Foresight::RothIRA.new(owner: p1, balance: 50_000) # Destination account
        ]
        household_with_less = Foresight::Household.new(
          members: [p1, p2], filing_status: 'married_filing_jointly', state: 'CA',
          accounts: accounts, income_sources: [], annual_expenses: 60_000,
          emergency_fund_floor: 25_000, withdrawal_hierarchy: [:cash, :taxable, :traditional, :roth]
        )
        args[:household] = household_with_less
        args[:ss_total] = 0
        
        events = strategy.plan_discretionary_events(**args)
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).not_to be_nil
        expect(conversion.amount).to eq(30_000)
      end
    end

    context 'with SS income' do
      it 'does not perform a conversion' do
        args[:ss_total] = 30_000
        events = strategy.plan_discretionary_events(**args)
        expect(events.any? { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }).to be false
      end
    end
  end

  describe 'ConditionalFixedAmountWithYears' do
    let(:strategy) { described_class::ConditionalFixedAmountWithYears.new(amount: 40_000, start_year: 2025, end_year: 2028) }

    context 'within the specified year range and no SS' do
      it 'converts the fixed amount' do
        args[:tax_year] = Foresight::TaxYear.new(year: 2026)
        args[:ss_total] = 0
        events = strategy.plan_discretionary_events(**args)
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).not_to be_nil
        expect(conversion.amount).to eq(40_000)
      end
    end

    context 'outside the start of the year range' do
      it 'does not perform a conversion' do
        args[:tax_year] = Foresight::TaxYear.new(year: 2024)
        args[:ss_total] = 0
        events = strategy.plan_discretionary_events(**args)
        expect(events.any? { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }).to be false
      end
    end

    context 'outside the end of the year range' do
      it 'does not perform a conversion' do
        args[:tax_year] = Foresight::TaxYear.new(year: 2029)
        args[:ss_total] = 0
        events = strategy.plan_discretionary_events(**args)
        expect(events.any? { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }).to be false
      end
    end

    context 'within the year range but with SS income' do
      it 'does not perform a conversion' do
        args[:tax_year] = Foresight::TaxYear.new(year: 2026)
        args[:ss_total] = 35_000
        events = strategy.plan_discretionary_events(**args)
        expect(events.any? { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }).to be false
      end
    end
  end
end
