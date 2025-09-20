# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../models/tax_year'

RSpec.describe Foresight::TaxYear do
  let(:tax_year) { described_class.new(year: 2023) }

  describe '#calculate' do
    context 'when filing status is single' do
      it 'calculates the correct tax for a single filer' do
        result = tax_year.calculate(filing_status: 'single', taxable_income: 50000)
        expect(result[:federal_tax].round(2)).to eq(6307.5)
        expect(result[:state_tax].round(2)).to eq(2000.0)
      end
    end

    context 'when filing status is mfj' do
      it 'calculates the correct tax for a married couple filing jointly' do
        result = tax_year.calculate(filing_status: 'mfj', taxable_income: 100000)
        expect(result[:federal_tax].round(2)).to eq(12615.0)
        expect(result[:state_tax].round(2)).to eq(4000.0)
      end
    end
  end

  describe '#calculate_capital_gains_tax' do
    it 'calculates the correct capital gains tax' do
        result = tax_year.calculate_capital_gains_tax(filing_status: 'single', taxable_income: 50000, capital_gains: 10000)
        expect(result.round(2)).to eq(1500.0)
    end
  end
end
