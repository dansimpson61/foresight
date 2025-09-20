# frozen_string_literal: true

require_relative '../spec_helper'
require 'date'
require_relative '../../models/annual_planner'
require_relative '../../models/household'
require_relative '../../models/person'
require_relative '../../models/income_sources'
require_relative '../../models/accounts'
require_relative '../../models/tax_year'

RSpec.describe Foresight::AnnualPlanner do
  let(:tax_year) { Foresight::TaxYear.new(year: 2023) }

  context 'with a pre-retirement household' do
    let(:person1) { Foresight::Person.new(name: 'John', date_of_birth: Date.new(1960, 5, 15)) }
    let(:person2) { Foresight::Person.new(name: 'Jane', date_of_birth: Date.new(1962, 8, 20)) }
    let(:incomes) do
        [
            Foresight::Salary.new(recipient: person1, annual_gross: 75000),
            Foresight::Pension.new(recipient: person2, annual_gross: 30000),
            # Claiming age 62 for person born 1960 (FRA 67) results in a 30% reduction.
            # 24000 * 0.7 = 16800
            Foresight::SocialSecurityBenefit.new(recipient: person1, pia_annual: 24000, claiming_age: 62)
        ]
    end
    let(:accounts) { [Foresight::TraditionalIRA.new(owner: person1, balance: 500000)] }
    let(:household) do
      Foresight::Household.new(
        members: [person1, person2],
        filing_status: 'mfj',
        state: 'CA',
        annual_expenses: 80000,
        emergency_fund_floor: 50000,
        accounts: accounts,
        income_sources: incomes,
        withdrawal_hierarchy: [:taxable, :traditional, :roth]
      )
    end
    let(:planner) { described_class.new(household: household, tax_year: tax_year) }

    describe '#compute_base_income' do
      it 'calculates the base income correctly without RMDs' do
        base_income = planner.send(:compute_base_income)
        # Gross Income = Salary (75k) + Pension (30k) + SS (16.8k) = 121.8k
        expect(base_income[:gross_income].round(2)).to eq(121800.0)
        # Provisional Income = 105k + 0.5 * 16.8k = 113.4k.
        # SS Taxable = (44k-32k)*.5 + (113.4k-44k)*.85, capped at 85% of benefit.
        # 6k + 58990 = 64990, capped at 14280.
        expect(base_income[:ss_taxable_baseline].round(2)).to eq(14280.0)
        # Taxable income = Salary (75k) + Pension (30k) + SS Taxable (14.28k) = 119.28k
        expect(base_income[:taxable_income].round(2)).to eq(119280.0)
        expect(base_income[:ss_total].round(2)).to eq(16800.0)
        expect(base_income[:rmds].round(2)).to eq(0)
      end
    end
  end

  context 'with a household of RMD age' do
    let(:retiree) { Foresight::Person.new(name: 'Sam', date_of_birth: Date.new(1950, 3, 1)) }
    let(:incomes) do
        [
            # Retiree born 1950 -> FRA is 66. Claiming at 65 is 12 months early.
            # Reduction factor = 1 - (12 * 5/9/100) = 0.9333. Annual benefit = 30000 * 0.9333 = 28000
            Foresight::SocialSecurityBenefit.new(recipient: retiree, pia_annual: 30000, claiming_age: 65)
        ]
    end
    let(:accounts) { [Foresight::TraditionalIRA.new(owner: retiree, balance: 750000)] }
    let(:household) do
      Foresight::Household.new(
        members: [retiree],
        filing_status: 'single',
        state: 'CA',
        annual_expenses: 60000,
        emergency_fund_floor: 50000,
        accounts: accounts,
        income_sources: incomes,
        withdrawal_hierarchy: [:taxable, :traditional, :roth]
      )
    end
    let(:planner) { described_class.new(household: household, tax_year: tax_year) }

    describe '#compute_base_income' do
      it 'calculates the base income correctly including RMDs' do
        base_income = planner.send(:compute_base_income)
        # RMD for age 73 with $750k balance is $750,000 / 26.5 = $28,301.89
        expect(base_income[:rmds]).to be_within(0.01).of(28301.89)

        # Actual SS benefit is $28,000 due to early claiming
        expect(base_income[:ss_total]).to be_within(0.01).of(28000.0)

        # Provisional income = RMD + 0.5 * SS = 28301.89 + 14000 = 42301.89
        # SS Taxable = (34000-25000)*0.5 + (42301.89-34000)*0.85 = 4500 + 7056.6065 = 11556.61
        expect(base_income[:ss_taxable_baseline]).to be_within(0.01).of(11556.61)
        
        # Gross Income = RMD + Total SS = 28301.89 + 28000 = 56301.89
        expect(base_income[:gross_income]).to be_within(0.01).of(56301.89)
        
        # Total Taxable = RMD + Taxable SS = 28301.89 + 11556.61 = 39858.50
        expect(base_income[:taxable_income]).to be_within(0.01).of(39858.5)
      end
    end
  end
end
