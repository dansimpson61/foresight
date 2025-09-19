# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../../models/plan_service'

RSpec.describe Foresight::PlanService do
  describe 'Scenario: The "Sweet Spot" Roth Conversion' do
    let(:current_year) { Date.today.year }
    # Set ages and years to create a clear "sweet spot"
    let(:retirement_age) { 64 }
    let(:ss_claim_age) { 67 }
    let(:birth_year) { current_year - (retirement_age - 1) } # Will be 64 next year

    let(:params) do
      {
        members: [
          { name: "Retiree", date_of_birth: "#{birth_year}-01-01" }
        ],
        filing_status: 'single',
        start_year: current_year,
        years: 10,
        accounts: [
          { type: 'TraditionalIRA', owner: 'Retiree', balance: 500_000 },
          { type: 'RothIRA', owner: 'Retiree', balance: 50_000 }
        ],
        income_sources: [
          # Salary should only apply for the first year of the simulation
          { type: 'Salary', recipient: 'Retiree', annual_gross: 100_000 },
          { type: 'SocialSecurityBenefit', recipient: 'Retiree', pia_annual: 30_000, claiming_age: ss_claim_age }
        ],
        strategies: [
          { key: 'do_nothing' },
          { key: 'fill_to_top_of_bracket', params: { ceiling: 47150 } } # 12% bracket for Single
        ],
        state: 'NY', annual_expenses: 0, emergency_fund_floor: 0, withdrawal_hierarchy: ['roth'],
        inflation_rate: 0.0,
        growth_assumptions: { traditional_ira: 0.0, roth_ira: 0.0, taxable: 0.0, cash: 0.0 }
      }
    end

    it 'correctly executes conversions only during the low-income years' do
      # Run the service and work with the returned Hash directly
      results_hash = described_class.run(params)
      
      conversion_yearly_data = results_hash[:data][:results]['fill_to_top_of_bracket'][:yearly]

      # Define the boundaries of our scenario
      retirement_year = current_year + 1
      ss_claim_year = current_year + (ss_claim_age - retirement_age) + 1

      sweet_spot_years = conversion_yearly_data.select do |year|
        year[:year] >= retirement_year && year[:year] < ss_claim_year
      end

      other_years = conversion_yearly_data.select do |year|
        year[:year] < retirement_year || year[:year] >= ss_claim_year
      end

      # 1. Assert that conversions HAPPENED during the sweet spot
      expect(sweet_spot_years.size).to be >= 2 # At least two full years
      sweet_spot_years.each do |year|
        expect(year[:actual_roth_conversion]).to be > 40000 # A substantial conversion
        expect(year[:base_taxable_income]).to eq(0) # Should have no other income
      end

      # 2. Assert that NO conversions happened in other years
      other_years.each do |year|
        expect(year[:actual_roth_conversion]).to eq(0)
      end
    end
  end
end
