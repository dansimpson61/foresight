# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/plan_service'
require_relative '../../models/household'
require_relative '../../models/person'
require_relative '../../models/accounts'
require_relative '../../models/income_sources'

RSpec.describe Foresight::PlanService do
  describe '.run with new data model' do
    let(:current_year) { Date.today.year }
    let(:params) do
      {
        # 1. Household & Demographics
        members: [
          { name: "You", date_of_birth: "#{current_year - 40}-01-01" },
          { name: "Spouse", date_of_birth: "#{current_year - 42}-01-01" }
        ],
        filing_status: 'mfj',
        state: 'NY',
        analysis_horizon: 30,
        start_year: current_year,

        # 2. Financial State
        accounts: [
          { type: 'TraditionalIRA', owner: 'You', balance: 500_000 },
          { type: 'RothIRA', owner: 'You', balance: 100_000 },
          { type: 'TaxableBrokerage', owners: ['You', 'Spouse'], balance: 200_000, cost_basis_fraction: 0.7 },
          { type: 'Cash', balance: 50_000 }
        ],
        emergency_fund_floor: 25_000,
        other_assets: 0,
        liabilities: 0,

        # 3. Income Streams
        income_sources: [
          { type: 'Salary', recipient: 'You', annual_gross: 150_000 },
          { type: 'Salary', recipient: 'Spouse', annual_gross: 75_000 },
          { type: 'SocialSecurity', recipient: 'You', fra_benefit: 30_000, claiming_age: 67 },
          { type: 'SocialSecurity', recipient: 'Spouse', fra_benefit: 21_600, claiming_age: 67 }
        ],

        # 4. Spending Plan
        annual_expenses: 80_000,

        # 5. Strategic Scenarios
        roth_conversion_strategy: { type: 'do_nothing', parameters: {} },
        withdrawal_hierarchy: ['cash', 'taxable', 'traditional', 'roth'],

        # 6. Economic Assumptions
        inflation_rate: 0.02,
        growth_assumptions: {
          traditional_ira: 0.03,
          roth_ira: 0.03,
          taxable: 0.03,
          cash: 0.005
        }
      }
    end

    it 'correctly builds the Household object from the new params' do
      service_instance = Foresight::PlanService.new
      
      # We test the private `build_household` method directly using `send`
      household = service_instance.send(:build_household, params)

      # Assertions
      expect(household).to be_a(Foresight::Household)
      
      # Household attributes
      expect(household.filing_status).to eq(:mfj)
      expect(household.state).to eq('NY')
      expect(household.annual_expenses).to eq(80_000.0)
      expect(household.emergency_fund_floor).to eq(25_000.0)
      expect(household.withdrawal_hierarchy).to eq([:cash, :taxable, :traditional, :roth])

      # Accounts
      expect(household.accounts.size).to eq(4)
      expect(household.traditional_iras.first.balance).to eq(500_000.0)
      expect(household.roth_iras.first.balance).to eq(100_000.0)
      expect(household.taxable_brokerage_accounts.first.balance).to eq(200_000.0)
      expect(household.cash_accounts.first.balance).to eq(50_000.0)

      # Income Sources
      expect(household.income_sources.size).to eq(4)
      expect(household.salaries.find { |s| s.recipient.name == 'You' }.annual_gross).to eq(150_000.0)
      ss_you = household.social_security_benefits.find { |s| s.recipient.name == 'You' }
      expect(ss_you.pia_annual).to eq(30_000.0)
      expect(ss_you.claiming_age).to eq(67)
    end
  end
end
