# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/household'
require_relative '../../models/tax_year'
require_relative '../../models/conversion_strategies'
require_relative '../../models/financial_event'

RSpec.describe Foresight::ConversionStrategies do
  let(:traditional_ira) { Foresight::TraditionalIRA.new(owner: 'Alice', balance: 200_000) }
  let(:roth_ira) { Foresight::RothIRA.new(owner: 'Alice', balance: 50_000) }
  let(:household) do
    instance_double(Foresight::Household,
                    filing_status: :mfj,
                    traditional_iras: [traditional_ira],
                    roth_iras: [roth_ira],
                    accounts_by_type: [],
                    withdrawal_hierarchy: [:traditional])
  end
  let(:tax_year) { instance_double(Foresight::TaxYear, year: 2023) }

  describe 'NoConversion Strategy' do
    it 'returns no events when no spending is needed' do
      strategy = Foresight::ConversionStrategies::NoConversion.new
      events = strategy.plan_discretionary_events(household: household, tax_year: tax_year, base_taxable_income: 50_000, spending_need: 0)
      expect(events).to be_empty
    end
  end

  describe 'BracketFill Strategy' do
    context 'when there is ample headroom in the bracket' do
      it 'creates a RothConversion event to fill the bracket' do
        strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: 89_450)
        base_taxable_income = 40_000
        
        # Headroom = 89,450 - 40,000 = 49,450. Cushion = 0.95. Target = 46977.5
        events = strategy.plan_discretionary_events(household: household, tax_year: tax_year, base_taxable_income: base_taxable_income, spending_need: 0)
        
        conversion_event = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion_event).not_to be_nil
        expect(conversion_event.amount).to be_within(0.01).of(46977.5)
      end
    end

    context 'when the base income is already over the ceiling' do
      it 'returns no conversion events' do
        strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: 89_450)
        events = strategy.plan_discretionary_events(household: household, tax_year: tax_year, base_taxable_income: 120_000, spending_need: 0)
        conversion_event = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion_event).to be_nil
      end
    end

    context 'when the available IRA balance is the limiting factor' do
      it 'creates a conversion up to the available balance' do
        allow(household).to receive(:traditional_iras).and_return([
          Foresight::TraditionalIRA.new(owner: 'Alice', balance: 30_000)
        ])
        strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: 89_450)
        base_taxable_income = 40_000
        
        events = strategy.plan_discretionary_events(household: household, tax_year: tax_year, base_taxable_income: base_taxable_income, spending_need: 0)
        conversion_event = events.find { |e| e.is_a?(Foresight::FinancialEvent::RothConversion) }
        expect(conversion_event).not_to be_nil
        # Target would be ~47k, but limited by 30k balance
        expect(conversion_event.amount).to eq(30_000)
      end
    end
  end
end