# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/person'
require_relative '../../models/accounts'

RSpec.describe Foresight::Account do
  let(:owner_rmd_at_73) { Foresight::Person.new(name: 'RMD at 73 Owner', date_of_birth: '1955-01-01') }
  let(:owner_rmd_at_75) { Foresight::Person.new(name: 'RMD at 75 Owner', date_of_birth: '1960-01-01') }

  describe 'Cash Account' do
    let(:account) { Foresight::Cash.new(balance: 1000) }

    it 'allows withdrawals' do
      withdrawal = account.withdraw(300)
      expect(account.balance).to eq(700)
      expect(withdrawal[:cash]).to eq(300)
      expect(withdrawal[:taxable_ordinary]).to eq(0)
      expect(withdrawal[:taxable_capital_gains]).to eq(0)
    end

    it 'does not go below zero' do
      account.withdraw(1200)
      expect(account.balance).to eq(0)
    end
  end

  describe 'Traditional IRA' do
    let(:account) { Foresight::TraditionalIRA.new(owner: owner_rmd_at_73, balance: 100_000) }

    it 'treats withdrawals as ordinary income' do
      withdrawal = account.withdraw(10_000)
      expect(account.balance).to eq(90_000)
      expect(withdrawal[:cash]).to eq(10_000)
      expect(withdrawal[:taxable_ordinary]).to eq(10_000)
    end

    it 'calculates RMDs correctly for an eligible person' do
      # For a person born in 1955, RMD age is 73.
      # Using the IRS Uniform Lifetime Table, divisor for age 73 from the model is 26.5
      expect(owner_rmd_at_73.rmd_start_age).to eq(73)
      rmd = account.calculate_rmd(73)
      expect(rmd).to be_within(0.01).of(100_000 / 26.5)
    end

    it 'returns an RMD of 0 for a non-eligible age' do
        rmd = account.calculate_rmd(65)
        expect(rmd).to eq(0)
    end
      
    it 'returns an RMD of 0 for a person not yet of RMD age' do
        account_for_younger_owner = Foresight::TraditionalIRA.new(owner: owner_rmd_at_75, balance: 100_000)
        expect(owner_rmd_at_75.rmd_start_age).to eq(75)
        rmd = account_for_younger_owner.calculate_rmd(73)
        expect(rmd).to eq(0)
    end
  end

  describe 'Roth IRA' do
    let(:account) { Foresight::RothIRA.new(owner: owner_rmd_at_73, balance: 50_000) }

    it 'allows tax-free withdrawals' do
      withdrawal = account.withdraw(5_000)
      expect(account.balance).to eq(45_000)
      expect(withdrawal[:cash]).to eq(5_000)
      expect(withdrawal[:taxable_ordinary]).to eq(0)
    end

    it 'allows deposits' do
        account.deposit(10_000)
        expect(account.balance).to eq(60_000)
    end
  end

  describe 'Taxable Brokerage' do
    let(:account) { Foresight::TaxableBrokerage.new(owners: [owner_rmd_at_73], balance: 200_000, cost_basis_fraction: 0.75) }

    it 'calculates capital gains on withdrawal' do
      withdrawal = account.withdraw(20_000)
      gains_portion = 20_000 * (1 - 0.75)
      
      expect(account.balance).to eq(180_000)
      expect(withdrawal[:cash]).to eq(20_000)
      expect(withdrawal[:taxable_capital_gains]).to eq(gains_portion)
      expect(withdrawal[:taxable_ordinary]).to eq(0)
    end
  end
end
