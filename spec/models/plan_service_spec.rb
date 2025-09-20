# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../models/plan_service'

# Helper to recursively symbolize keys in hashes and arrays of hashes
def symbolize_keys(value)
  case value
  when Hash
    value.each_with_object({}) do |(key, val), result|
      new_key = key.is_a?(String) ? key.to_sym : key
      result[new_key] = symbolize_keys(val)
    end
  when Array
    value.map { |v| symbolize_keys(v) }
  else
    value
  end
end

RSpec.describe Foresight::PlanService do
  let(:example_payload) do
    {
      'members' => [
        { 'name' => 'Alice', 'date_of_birth' => '1961-06-15' },
        { 'name' => 'Bob',   'date_of_birth' => '1967-02-10' }
      ],
      'filing_status' => 'mfj',
      'state' => 'NY',
      'start_year' => 2025,
      'years' => 30,
      'accounts' => [
        { 'type' => 'TraditionalIRA', 'owner' => 'Alice', 'balance' => 100_000.0 },
        { 'type' => 'RothIRA', 'owner' => 'Alice', 'balance' => 50_000.0 },
        { 'type' => 'TaxableBrokerage', 'owners' => ['Alice','Bob'], 'balance' => 20_000.0, 'cost_basis_fraction' => 0.7 }
      ],
      'emergency_fund_floor' => 20_000.0,
      'income_sources' => [
        { 'type' => 'SocialSecurityBenefit', 'recipient' => 'Alice', 'pia_annual' => 24_000.0, 'claiming_age' => 67 },
        { 'type' => 'SocialSecurityBenefit', 'recipient' => 'Bob',   'pia_annual' => 24_000.0, 'claiming_age' => 65 }
      ],
      'annual_expenses' => 60_000.0,
      'withdrawal_hierarchy' => ['taxable', 'traditional', 'roth'],
      'inflation_rate' => 0.02,
      'growth_assumptions' => { 'traditional_ira' => 0.02, 'roth_ira' => 0.03, 'taxable' => 0.01, 'cash' => 0.005 },
      'strategies' => [ { 'key' => 'do_nothing' } ]
    }
  end
  
  let(:symbolized_payload) { symbolize_keys(example_payload) }

  describe '.run' do
    it "runs the 'do_nothing' scenario and returns a complete, structurally valid result" do
      result = described_class.run(symbolized_payload)
      
      # Verify the top-level structure
      expect(result).to have_key(:data)
      expect(result[:data][:results]).to have_key('do_nothing')
      
      # Verify the completeness of the strategy's result payload
      do_nothing_result = result[:data][:results]['do_nothing']
      expect(do_nothing_result).to be_a(Hash)
      expect(do_nothing_result).to have_key(:aggregate)
      expect(do_nothing_result).to have_key(:yearly)
      
      # Verify the simulation ran for the correct number of years
      yearly_data = do_nothing_result[:yearly]
      expect(yearly_data).to be_an(Array)
      expect(yearly_data.size).to eq(30)
      
      # Verify that the "do_nothing" strategy behaved as expected
      aggregate_data = do_nothing_result[:aggregate]
      expect(aggregate_data).to be_a(Hash)
      expect(aggregate_data[:cumulative_roth_conversions]).to eq(0)
    end
  end
end
