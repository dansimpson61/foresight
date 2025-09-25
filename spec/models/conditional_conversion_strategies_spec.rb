#!/usr/bin/env ruby
# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/household'
require_relative '../../models/person'
require_relative '../../models/accounts'
require_relative '../../models/tax_year'
require_relative '../../models/financial_event'
require_relative '../../models/conditional_conversion_strategies'

RSpec.describe Foresight::ConversionStrategies do
  let(:p1) { Foresight::Person.new(birth_year: 1960, name: 'Person1') }
  let(:p2) { Foresight::Person.new(birth_year: 1962, name: 'Person2') }
  let(:household) do
    Foresight::Household.new(filing_status: 'Married Filing Jointly', primary_taxpayer: p1, spouse: p2).tap do |h|
      h.add_account(Foresight::TraditionalIRA.new(owner: p1, balance: 500_000))
      h.add_account(Foresight::RothIRA.new(owner: p1, balance: 100_000))
    end
  end
  let(:tax_year) { Foresight::TaxYear.new(year: 2024, brackets: tax_brackets_2024['Married Filing Jointly']) }
  let(:base_args) do
    {
      household: household,
      tax_year: tax_year,
      base_taxable_income: 0,
      spending_need: 0,
      provisional_income_before_strategy: 0,
      standard_deduction: 29200
    }
  end

  # Mock tax brackets for simplicity
  let(:tax_brackets_2024) do
    {
      'Married Filing Jointly' => [
        { rate: 0.10, ceiling: 23200 },
        { rate: 0.12, ceiling: 94300 },
        { rate: 0.22, ceiling: 201050 }
      ]
    }
  end

  # Set up mock Social Security taxability thresholds
  before do
    allow(tax_year).to receive(:social_security_taxability_thresholds).and_return({
      'phase1_start' => 32000,
      'phase2_start' => 44000
    })
  end

  describe 'ConditionalBracketFill' do
    let(:strategy) { described_class::ConditionalBracketFill.new(ceiling: 94300) }

    context 'when Social Security is NOT claimed (ss_total is 0)' do
      it 'performs a Roth conversion to fill the specified tax bracket' do
        events = strategy.plan_discretionary_events(**base_args.merge(ss_total: 0))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).not_to be_nil
        # Expected: (94300 ceiling + 29200 std deduction) - 0 base income = 123500
        # With 5% cushion: 123500 * 0.95 = 117325
        expect(conversion.amount).to be_within(1).of(117325)
      end
    end

    context 'when Social Security IS claimed (ss_total > 0)' do
      it 'does not perform a Roth conversion' do
        events = strategy.plan_discretionary_events(**base_args.merge(ss_total: 50000))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).to be_nil
      end

      it 'still allocates funds to meet spending needs' do
        events = strategy.plan_discretionary_events(**base_args.merge(ss_total: 50000, spending_need: 10000))
        withdrawal = events.find { |e| e.is_a?(Foresight::FinancialEvent::SpendingWithdrawal) }
        expect(withdrawal).not_to be_nil
        expect(withdrawal.amount_withdrawn).to eq(10000)
      end
    end
  end

  describe 'ConditionalBracketFillByYear' do
    let(:strategy) { described_class::ConditionalBracketFillByYear.new(ceiling: 94300, start_year: 2024, end_year: 2026) }

    context 'when within the specified year range and no SS is claimed' do
      it 'performs a Roth conversion' do
        events = strategy.plan_discretionary_events(**base_args.merge(tax_year: Foresight::TaxYear.new(year: 2025, brackets: {})))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).not_to be_nil
      end
    end

    context 'when outside the specified year range' do
      it 'does not perform a conversion before the start year' do
        events = strategy.plan_discretionary_events(**base_args.merge(tax_year: Foresight::TaxYear.new(year: 2023, brackets: {})))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).to be_nil
      end

      it 'does not perform a conversion after the end year' do
        events = strategy.plan_discretionary_events(**base_args.merge(tax_year: Foresight::TaxYear.new(year: 2027, brackets: {})))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).to be_nil
      end
    end

    context 'when SS is claimed within the year range' do
      it 'does not perform a conversion' do
        events = strategy.plan_discretionary_events(**base_args.merge(ss_total: 50000, tax_year: Foresight::TaxYear.new(year: 2025, brackets: {})))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).to be_nil
      end
    end
  end

  describe 'ConditionalFixedAmount' do
    let(:strategy) { described_class::ConditionalFixedAmount.new(amount: 50000) }

    context 'when Social Security is NOT claimed' do
      it 'converts the specified fixed amount' do
        events = strategy.plan_discretionary_events(**base_args.merge(ss_total: 0))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).not_to be_nil
        expect(conversion.amount).to eq(50000)
      end

      it 'converts only the available balance if less than the fixed amount' do
        household.traditional_iras.first.balance = 40000
        events = strategy.plan_discretionary_events(**base_args.merge(ss_total: 0))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion.amount).to eq(40000)
      end
    end

    context 'when Social Security IS claimed' do
      it 'does not perform a conversion' do
        events = strategy.plan_discretionary_events(**base_args.merge(ss_total: 50000))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).to be_nil
      end
    end
  end

  describe 'ConditionalFixedAmountByYear' do
    let(:strategy) { described_class::ConditionalFixedAmountByYear.new(amount: 60000, start_year: 2025, end_year: 2027) }

    context 'when within the year range and no SS is claimed' do
      it 'converts the specified fixed amount' do
        events = strategy.plan_discretionary_events(**base_args.merge(tax_year: Foresight::TaxYear.new(year: 2026, brackets: {})))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).not_to be_nil
        expect(conversion.amount).to eq(60000)
      end
    end

    context 'when outside the year range' do
      it 'does not perform a conversion before the start year' do
        events = strategy.plan_discretionary_events(**base_args.merge(tax_year: Foresight::TaxYear.new(year: 2024, brackets: {})))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).to be_nil
      end

      it 'does not perform a conversion after the end year' do
        events = strategy.plan_discretionary_events(**base_args.merge(tax_year: Foresight::TaxYear.new(year: 2028, brackets: {})))
        conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion).to be_nil
      end
    end

    context 'when SS is claimed within the year range' do
      it 'does not perform a conversion' do
         events = strategy.plan_discretionary_events(**base_args.merge(ss_total: 50000, tax_year: Foresight::TaxYear.new(year: 2026, brackets: {})))
         conversion = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
         expect(conversion).to be_nil
      end
    end
  end
end
