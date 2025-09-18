# frozen_string_literal: true

require 'json'
require_relative '../foresight'
include Foresight

# This smoke test uses the current, correct data structure for the PlanService.
params = {
  members: [
    { name: 'Alice', date_of_birth: '1961-06-15' },
    { name: 'Bob',   date_of_birth: '1967-02-10' }
  ],
  filing_status: 'mfj',
  state: 'NY',
  start_year: 2025,
  years: 5,
  accounts: [
    { type: 'TraditionalIRA', owner: 'Alice', balance: 100_000.0 },
    { type: 'RothIRA', owner: 'Alice', balance: 50_000.0 },
    { type: 'TaxableBrokerage', owners: ['Alice','Bob'], balance: 20_000.0, cost_basis_fraction: 0.7 },
    { type: 'Cash', balance: 25_000.0 }
  ],
  emergency_fund_floor: 20_000.0,
  income_sources: [
    { type: 'SocialSecurityBenefit', recipient: 'Alice', pia_annual: 24_000.0, claiming_age: 67 },
    { type: 'SocialSecurityBenefit', recipient: 'Bob',   pia_annual: 24_000.0, claiming_age: 65 }
  ],
  annual_expenses: 60_000.0,
  withdrawal_hierarchy: ['taxable', 'traditional', 'roth'],
  inflation_rate: 0.02,
  growth_assumptions: { traditional_ira: 0.02, roth_ira: 0.03, taxable: 0.01, cash: 0.005 },
  strategies: [ { key: 'do_nothing' }, { key: 'fill_to_top_of_bracket' } ]
}

json = PlanService.run(params)
out = JSON.parse(json)
raise 'bad schema_version' unless out['schema_version']
raise 'bad mode' unless out['mode'] == 'multi_year'
raise 'missing data' unless out['data']

res = out['data']['results']['do_nothing']
raise 'missing do_nothing results' unless res

agg = res['aggregate']
raise 'missing all_in_tax agg' unless agg.key?('cumulative_all_in_tax')

y1 = res['yearly'].first
raise 'missing yearly all_in_tax' unless y1.key?('all_in_tax')

puts 'PlanService smoke PASS'
