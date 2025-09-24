# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../../models/plan_service'

RSpec.describe Foresight::PlanService do
  describe 'Scenario: The "Sweet Spot" Roth Conversion' do
    let(:current_year) { Date.today.year }
    let(:retirement_age) { 65 } # Align with the model's logic
    let(:ss_claim_age) { 67 }
    let(:birth_year) { current_year - (retirement_age - 1) } 

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
          { type: 'Salary', recipient: 'Retiree', annual_gross: 100_000, retirement_age: retirement_age },
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
      results_hash = described_class.run(params)
      
      conversion_yearly_data = results_hash[:data][:results]['fill_to_top_of_bracket'][:yearly]

      retirement_year = current_year + 1
      ss_claim_year = current_year + (ss_claim_age - (retirement_age - 1))

      sweet_spot_years = conversion_yearly_data.select do |year|
        year[:year] >= retirement_year && year[:year] < ss_claim_year
      end

      other_years = conversion_yearly_data.select do |year|
        year[:year] < retirement_year
      end
      
      def total_conversion_for_year(year)
          return 0 unless year[:financial_events]
          year[:financial_events].select{|e| e.is_a?(Foresight::FinancialEvent::RothConversion)}.sum(&:amount)
      end

      # 1. Assert that conversions HAPPENED during the sweet spot
      expect(sweet_spot_years.size).to be >= 1
      sweet_spot_years.each do |year|
        conversion_amount = total_conversion_for_year(year)
        expect(conversion_amount).to be > 40000
      end

      # 2. Assert that NO conversions happened in other years
      other_years.each do |year|
        conversion_amount = total_conversion_for_year(year)
        expect(conversion_amount).to eq(0)
      end
    end
  end
end
