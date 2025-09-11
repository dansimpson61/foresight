# frozen_string_literal: true

require_relative '../foresight'
include Foresight

alice = Person.new(name: 'Alice', date_of_birth: '1961-06-15')
acct = TraditionalIRA.new(owner: alice, balance: 90_000)
ss = SocialSecurityBenefit.new(recipient: alice, start_year: 2025, pia_annual: 24_000, cola_rate: 0.0)
hh = Household.new(members: [alice], target_spending_after_tax: 40_000, desired_tax_bracket_ceiling: 94_300, accounts: [acct], income_sources: [ss])

ap = AnnualPlanner.new(household: hh, tax_year: TaxYear.new(year: 2025))
res = ap.generate_strategy(ConversionStrategies::BracketFill.new)

raise 'narration missing state tax' unless res.narration.include?('NY state:')
raise 'narration missing IRMAA' unless res.narration.include?('IRMAA Part B:')

puts 'Narration smoke PASS'
