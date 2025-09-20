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
  let(:household) do
    Foresight::Household.new(
      members: [person1, person2],
      filing_status: :mfj,
      state: 'NY',
      accounts: [
        Foresight::TraditionalIRA.new(owner: person1, balance: 500_000),
        Foresight::RothIRA.new(owner: person1, balance: 100_000),
        Foresight::TaxableBrokerage.new(owners: [person1, person2], balance: 200_000, cost_basis_fraction: 0.5)
      ],
      income_sources: [
        Foresight::SocialSecurityBenefit.new(recipient: person1, pia_annual: 30_000, claiming_age: 67)
      ],
      annual_expenses: 60_000,
      emergency_fund_floor: 25_000,
      withdrawal_hierarchy: [:taxable, :traditional, :roth]
    )
  end
  let(:tax_year) { Foresight::TaxYear.new(year: 2027) } # John is 67, Jane is 65
  let(:planner) { described_class.new(household: household, tax_year: tax_year) }

  describe '#compute_base_income' do
    it 'correctly calculates gross and taxable income including taxable Social Security' do
      # In 2027, John is 67 and receives his full SS benefit of 30,000
      # Provisional income = 0 (other income) + 0.5 * 30000 = 15000
      # This is below the first threshold ($32k for MFJ), so SS is not taxable
      base_income = planner.send(:compute_base_income)
      
      expect(base_income[:gross_income]).to eq(30_000)
      expect(base_income[:ss_taxable_baseline]).to eq(0)
      expect(base_income[:taxable_income]).to eq(0)
    end
  end
  
  describe '#generate_strategy' do
    let(:no_conversion_strategy) { Foresight::ConversionStrategies::NoConversion.new }
    
    it 'sequences financial events correctly' do
      # In 2027, John is 67, so no RMDs yet.
      result = planner.generate_strategy(no_conversion_strategy)
      
      # 1. Income (SS) is calculated
      # 2. No RMDs, no conversions
      # 3. Net cash from income = 30,000 (SS) - 0 (tax) = 30,000
      # 4. Remaining spending need = 60,000 (expenses) - 30,000 = 30,000
      # 5. Withdrawals are made from taxable account to cover the 30k need.
      
      expect(result.remaining_spending_need).to be > 0
      
      withdrawal_event = result.financial_events.find { |e| e.is_a?(Foresight::FinancialEvent::SpendingWithdrawal) }
      expect(withdrawal_event).not_to be_nil
      expect(withdrawal_event.source_account).to be_a(Foresight::TaxableBrokerage)
      expect(withdrawal_event.amount_withdrawn).to be_within(0.01).of(30_000)
      
      # Capital gains = 30,000 * (1 - 0.5 cost basis) = 15,000
      expect(withdrawal_event.taxable_capital_gains).to eq(15_000)
    end
    
    it 're-calculates SS taxability after a Roth conversion' do
        # We need a strategy that performs a conversion
        bracket_fill_strategy = Foresight::ConversionStrategies::BracketFill.new(ceiling: 89450)
        allow(bracket_fill_strategy).to receive(:conversion_amount).and_return(50_000)

        result = planner.generate_strategy(bracket_fill_strategy)
        
        # Original taxable SS was 0.
        # After a 50k conversion, provisional income = 50,000 + 0.5 * 30,000 = 65,000
        # This is above the second threshold ($44k), so SS becomes highly taxable.
        # Taxable SS = (44k-32k)*0.5 + (65k-44k)*0.85 = 6000 + 17850 = 23850
        # Capped at 85% of total benefit = 0.85 * 30000 = 25500. So, 23,850.
        expect(result.ss_taxable_baseline).to eq(0) # Before conversion
        expect(result.ss_taxable_post).to be_within(0.01).of(23_850) # After conversion
        expect(result.ss_taxable_increase).to be_within(0.01).of(23_850)
    end
  end
end
