# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/financial_event'
require_relative '../../models/accounts' # For source_account objects

RSpec.describe Foresight::FinancialEvent do
  let(:year) { 2024 }
  let(:person) { Foresight::Person.new(name: 'Pat', date_of_birth: Date.new(1960, 1, 1)) }
  let(:traditional_ira) { Foresight::TraditionalIRA.new(owner: person, balance: 100_000) }
  let(:roth_ira) { Foresight::RothIRA.new(owner: person, balance: 50_000) }

  describe 'RequiredMinimumDistribution' do
    it 'initializes correctly' do
      event = described_class::RequiredMinimumDistribution.new(year: year, source_account: traditional_ira, amount: 5000)
      expect(event.year).to eq(year)
      expect(event.source_account).to eq(traditional_ira)
      expect(event.amount).to eq(5000)
      expect(event.taxable_ordinary).to eq(5000)
      expect(event.taxable_capital_gains).to eq(0)
    end
  end

  describe 'RothConversion' do
    it 'initializes correctly' do
      event = described_class::RothConversion.new(year: year, source_account: traditional_ira, destination_account: roth_ira, amount: 10_000)
      expect(event.year).to eq(year)
      expect(event.source_account).to eq(traditional_ira)
      expect(event.destination_account).to eq(roth_ira)
      expect(event.amount).to eq(10_000)
      expect(event.taxable_ordinary).to eq(10_000)
      expect(event.taxable_capital_gains).to eq(0)
    end
  end

  describe 'SpendingWithdrawal' do
    it 'initializes correctly for a taxable withdrawal' do
      event = described_class::SpendingWithdrawal.new(
        year: year,
        source_account: traditional_ira,
        amount_withdrawn: 7000,
        taxable_ordinary: 7000,
        taxable_capital_gains: 0
      )
      expect(event.year).to eq(year)
      expect(event.source_account).to eq(traditional_ira)
      expect(event.amount_withdrawn).to eq(7000)
      expect(event.taxable_ordinary).to eq(7000)
      expect(event.taxable_capital_gains).to eq(0)
    end

    it 'initializes correctly for a non-taxable withdrawal' do
      event = described_class::SpendingWithdrawal.new(
        year: year,
        source_account: roth_ira,
        amount_withdrawn: 8000
      )
      expect(event.year).to eq(year)
      expect(event.source_account).to eq(roth_ira)
      expect(event.amount_withdrawn).to eq(8000)
      expect(event.taxable_ordinary).to eq(0)
      expect(event.taxable_capital_gains).to eq(0)
    end
  end
end
