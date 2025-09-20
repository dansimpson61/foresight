# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/household'
require_relative '../../models/tax_year'
require_relative '../../models/conversion_strategies'

RSpec.describe Foresight::ConversionStrategies do
  let(:household) do
    instance_double(Foresight::Household,
                    filing_status: :mfj,
                    traditional_iras: [
                      instance_double(Foresight::TraditionalIRA, balance: 200_000)
                    ])
  end
  let(:tax_year) { instance_double(Foresight::TaxYear) }

  before do
    allow(tax_year).to receive(:standard_deduction).with(:mfj).and_return(27700)
  end

  describe 'NoConversion Strategy' do
    it 'always returns a conversion amount of 0' do
      strategy = Foresight::ConversionStrategies::NoConversion.new
      amount = strategy.conversion_amount(household: household, tax_year: tax_year, base_taxable_income: 50_000)
      expect(amount).to eq(0)
    end
  end

  describe 'BracketFill Strategy' do
    context 'when there is ample headroom in the bracket' do
      it 'calculates the correct conversion amount to fill the bracket' do
        # Target: Fill the 12% bracket, which ends at $89,450 for MFJ in 2023
        strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: 89_450)
        
        # Base income already uses up some of the standard deduction and headroom
        base_taxable_income = 40_000
        
        # Taxable after deduction = 40_000 - 27_700 = 12_300
        # Headroom to ceiling = 89_450 - 12_300 = 77_150
        # Target conversion (with 5% cushion) = 77_150 * 0.95 = 73_292.5
        
        amount = strategy.conversion_amount(household: household, tax_year: tax_year, base_taxable_income: base_taxable_income)
        expect(amount).to be_within(0.01).of(73_292.5)
      end
    end

    context 'when the base income after deductions is already over the ceiling' do
      it 'returns a conversion amount of 0' do
        strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: 89_450)
        # 120,000 (base) - 27,700 (deduction) = 92,300, which is > 89,450
        amount = strategy.conversion_amount(household: household, tax_year: tax_year, base_taxable_income: 120_000)
        expect(amount).to eq(0)
      end
    end

    context 'when the available IRA balance is the limiting factor' do
      it 'converts only up to the available balance' do
        allow(household).to receive(:traditional_iras).and_return([
          instance_double(Foresight::TraditionalIRA, balance: 50_000)
        ])
        
        strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: 89_450)
        base_taxable_income = 40_000 # Would normally ask for ~73k conversion
        
        amount = strategy.conversion_amount(household: household, tax_year: tax_year, base_taxable_income: base_taxable_income)
        expect(amount).to eq(50_000)
      end
    end
  end
end
