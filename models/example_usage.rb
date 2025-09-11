# frozen_string_literal: true

require_relative '../foresight'
require 'date'

include Foresight

# Example couple setup
alice = Person.new(name: 'Alice', date_of_birth: '1961-06-15')
bob   = Person.new(name: 'Bob', date_of_birth: '1967-02-10')

accounts = [
  TraditionalIRA.new(owner: alice, balance: 1_150_000),
  RothIRA.new(owner: alice, balance: 150_000),
  TraditionalIRA.new(owner: bob, balance: 250_000),
  RothIRA.new(owner: bob, balance: 100_000),
  TaxableBrokerage.new(owners: [alice, bob], balance: 10_000, cost_basis_fraction: 0.65)
]

income_sources = [
#  Pension.new(recipient: alice, annual_gross: 24_000),
  # Alice has already claimed
  SocialSecurityBenefit.new(recipient: alice, pia_annual: 30_000, start_year: 2025, cola_rate: 0.02),
  # Bob delays one year
  SocialSecurityBenefit.new(recipient: bob, pia_annual: 24_000, start_year: 2029, cola_rate: 0.02)
]

household = Household.new(
  members: [alice, bob],
  target_spending_after_tax: 100_000,
  desired_tax_bracket_ceiling: 94_300, # top of (truncated) 24% example
  accounts: accounts,
  income_sources: income_sources
)

planner = AnnualPlanner.new(household: household, tax_year: TaxYear.new(year: 2025))
results = planner.run_comparison

results.each do |res|
  puts "\n== Strategy: #{res.strategy_name} =="
  puts res.narration
  puts "Effective tax rate: #{(res.effective_tax_rate * 100).round(2)}%"
  puts "Withdrawals: #{res.withdrawals[:detail].inspect}"
end

# IMPORTANT: Run multi-strategy comparison & JSON export BEFORE any long simulation mutates account balances
puts "\nMulti-strategy 5-year comparison (with 2% inflation):"
life_compare = LifePlanner.new(household: household, start_year: 2025, years: 5, inflation_rate: 0.02)
strategies = [
  ConversionStrategies::NoConversion.new,
  ConversionStrategies::BracketFill.new
]
comparison = life_compare.run_multi(strategies)

comparison.each do |name, data|
  agg = data[:aggregate]
  puts "Strategy #{name}: cum_tax=#{agg.cumulative_federal_tax} cum_conv=#{agg.cumulative_roth_conversions} end_trad=#{agg.ending_traditional_balance} proj_first_rmd_pressure=#{agg.projected_first_rmd_pressure}"
end

# Write JSON report (captures true starting balances now)
json_path = File.join(__dir__, '..', 'life_plan_report.json')
File.write(json_path, life_compare.to_json_report(comparison, strategies: strategies.map(&:name)))
puts "\nJSON report written to #{json_path}"

puts "\nMulti-year (35-year) projection using BracketFill strategy:"
life = LifePlanner.new(household: household, start_year: 2025, years: 35)
life.run(strategy: ConversionStrategies::BracketFill.new).each do |ys|
  puts "Year #{ys.year}: actual_conv=#{ys.actual_roth_conversion} tax=#{ys.federal_tax} trad_end=#{ys.ending_traditional_balance} rmd_pressure=#{ys.future_rmd_pressure} incr_rate=#{ys.conversion_incremental_marginal_rate}"
end
