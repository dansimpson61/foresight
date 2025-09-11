# frozen_string_literal: true

require 'json'
require_relative '../foresight'
include Foresight

params = {
  members: [
    { name: 'Alice', date_of_birth: '1961-06-15' },
    { name: 'Bob',   date_of_birth: '1967-02-10' }
  ],
  accounts: [
    { type: 'TraditionalIRA', owner: 'Alice', balance: 100_000.0 },
    { type: 'RothIRA', owner: 'Alice', balance: 50_000.0 },
    { type: 'TaxableBrokerage', owners: ['Alice','Bob'], balance: 20_000.0, cost_basis_fraction: 0.7 }
  ],
  income_sources: [
    { type: 'SocialSecurityBenefit', recipient: 'Alice', start_year: 2025, pia_annual: 24_000.0, cola_rate: 0.0 },
    { type: 'SocialSecurityBenefit', recipient: 'Bob', start_year: 2030, pia_annual: 24_000.0, cola_rate: 0.0 }
  ],
  target_spending_after_tax: 60_000.0,
  desired_tax_bracket_ceiling: 94_300.0,
  start_year: 2025,
  years: 2,
  growth_assumptions: { traditional_ira: 0.02, roth_ira: 0.03, taxable: 0.01 },
  strategies: [ { key: 'none' } ]
}

json = PlanService.run(params)
out = JSON.parse(json)
raise 'bad schema_version' unless out['schema_version']
raise 'bad mode' unless out['mode'] == 'multi_year'
raise 'missing data' unless out['data']

res = out['data']['results'].values.first
agg = res['aggregate']
raise 'missing all_in_tax agg' unless agg.key?('cumulative_all_in_tax')
y1 = res['yearly'].first
raise 'missing yearly all_in_tax' unless y1.key?('all_in_tax')
raise 'missing phases' unless res['phases'].is_a?(Array)

puts 'PlanService smoke PASS'
