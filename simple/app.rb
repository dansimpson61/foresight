# An Ode to Joy: A Radically Simplified Financial Simulator
# All logic, data, and routing are contained in this single file.

require 'sinatra'
require 'slim'
require 'json'
require 'yaml'

# --- Configuration ---
set :port, 9293
set :bind, '0.0.0.0'
set :views, File.expand_path('views', __dir__)
set :public_folder, File.expand_path('public', __dir__)

# --- Default Financial Profile ---
# Loaded from an external YAML file for easier configuration.
def symbolize_keys(obj)
  case obj
  when Hash
    obj.each_with_object({}) do |(k, v), result|
      result[k.to_sym] = symbolize_keys(v)
    end
  when Array
    obj.map { |v| symbolize_keys(v) }
  else
    obj
  end
end

DEFAULT_PROFILE = symbolize_keys(YAML.load_file(File.expand_path('profile.yml', __dir__)))

# --- Tax Data (Embedded for Simplicity) ---
# We only need data for the simulation's start year.
# The simulation will not model changes in tax law.
TAX_BRACKETS_2024 = {
  'mfj' => {
    'ordinary' => [
      { 'income' => 0, 'rate' => 0.10 },
      { 'income' => 23_200, 'rate' => 0.12 },
      { 'income' => 94_300, 'rate' => 0.22 },
      { 'income' => 201_050, 'rate' => 0.24 },
      { 'income' => 383_900, 'rate' => 0.32 } # Simplified upper brackets
    ],
    'capital_gains' => [
      { 'income' => 0, 'rate' => 0.0 },
      { 'income' => 94_050, 'rate' => 0.15 },
      { 'income' => 583_750, 'rate' => 0.20 }
    ],
    'social_security_provisional_income' => {
      'phase1_start' => 32_000,
      'phase2_start' => 44_000
    }
  },
  'standard_deduction' => {
    'mfj' => 29_200
  }
}.freeze

# --- The Application ---
get '/' do
  # Run simulations with the default profile for the initial page load
  do_nothing_results = run_simulation(strategy: :do_nothing, profile: DEFAULT_PROFILE)
  fill_bracket_results = run_simulation(strategy: :fill_to_bracket, strategy_params: { ceiling: 94_300 }, profile: DEFAULT_PROFILE)

  # Pass results to the view
  slim :index, locals: {
    profile: DEFAULT_PROFILE,
    do_nothing_results: do_nothing_results,
    fill_bracket_results: fill_bracket_results
  }
end

post '/run' do
  content_type :json
  payload = JSON.parse(request.body.read, symbolize_names: true)

  # Run simulations with the provided profile
  do_nothing_results = run_simulation(strategy: :do_nothing, profile: payload)
  fill_bracket_results = run_simulation(strategy: :fill_to_bracket, strategy_params: { ceiling: 94_300 }, profile: payload)

  {
    do_nothing_results: do_nothing_results,
    fill_bracket_results: fill_bracket_results
  }.to_json
end

# --- Simulation Engine ---
class Simulator
  def run(strategy:, strategy_params: {}, profile: DEFAULT_PROFILE)
    # Deep copy the profile to prevent mutation between runs
    profile = Marshal.load(Marshal.dump(profile))
    yearly_results = []
    accounts = profile[:accounts]

    profile[:years_to_simulate].times do |i|
      current_year = profile[:start_year] + i
      person = profile[:members].first
      age = get_age(person[:date_of_birth], current_year)
      annual_expenses = profile[:household][:annual_expenses]

      # A. Calculate Gross Income (Non-Discretionary)
      ss_benefit = get_social_security_benefit(profile[:income_sources].first, age)
      rmd = get_rmd(age, accounts)
      gross_income_from_sources = ss_benefit + rmd

      # B. Determine Spending Shortfall and Withdrawals
      # This is a simplification. A real model would account for taxes on withdrawals.
      # For clarity, we assume withdrawals are made to cover the gap after income is received.
      spending_shortfall = [annual_expenses - gross_income_from_sources, 0].max
      spending_withdrawals = withdraw_for_spending(spending_shortfall, accounts)

      # C. Determine Roth Conversion Amount
      conversion_events = determine_conversion_events(
        strategy: strategy,
        strategy_params: strategy_params,
        accounts: accounts,
        rmd: rmd,
        ss_benefit: ss_benefit,
        spending_withdrawals: spending_withdrawals
      )

      # D. Finalize Financial Picture for the Year
      all_events = spending_withdrawals + conversion_events
      withdrawals_for_spending_amount = spending_withdrawals.sum { |e| e[:amount] }
      total_gross_income = gross_income_from_sources + withdrawals_for_spending_amount

      # Finalize Taxable Income
      taxable_ord_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_ordinary] }
      taxable_cg_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_capital_gains] }
      conversion_amount = conversion_events.sum { |e| e[:amount] }

      provisional_income = rmd + taxable_ord_from_withdrawals + conversion_amount
      final_taxable_ss = calculate_taxable_social_security(provisional_income, ss_benefit)

      total_ordinary_income = rmd + final_taxable_ss + taxable_ord_from_withdrawals + conversion_amount
      taxes = calculate_taxes(total_ordinary_income, taxable_cg_from_withdrawals)

      # E. Record results
      yearly_results << {
        year: current_year, age: age,
        annual_expenses: annual_expenses.round(0),
        total_gross_income: total_gross_income.round(0),
        income_sources: { social_security: ss_benefit, rmd: rmd, withdrawals: withdrawals_for_spending_amount },
        taxable_income_breakdown: {
          rmd: rmd, taxable_ss: final_taxable_ss, conversions: conversion_amount,
          taxable_withdrawals: taxable_ord_from_withdrawals, capital_gains: taxable_cg_from_withdrawals
        },
        total_tax: taxes[:total].round(0),
        ending_net_worth: accounts.sum { |a| a[:balance] }.round(0)
      }

      # F. Grow assets for next year
      grow_assets(accounts, profile[:growth_assumptions])
      profile[:household][:annual_expenses] *= (1 + profile[:inflation_rate])
    end

    { yearly: yearly_results, aggregate: aggregate_results(yearly_results) }
  end

  private

  def determine_conversion_events(strategy:, strategy_params:, accounts:, rmd:, ss_benefit:, spending_withdrawals:)
    return [] if strategy == :do_nothing

    # This is the core logic for the "fill_to_bracket" strategy
    taxable_ord_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_ordinary] }

    # This is the key calculation: determine the taxable income *before* the discretionary conversion
    provisional_income_before_conversion = rmd + taxable_ord_from_withdrawals
    taxable_ss_before_conversion = calculate_taxable_social_security(provisional_income_before_conversion, ss_benefit)
    taxable_income_before_conversion = rmd + taxable_ss_before_conversion + taxable_ord_from_withdrawals

    headroom = strategy_params[:ceiling] - taxable_income_before_conversion

    # A more robust model would iteratively solve for the ideal conversion amount.
    # This simplified version uses the initial headroom, which is a reasonable approximation.
    conversion_amount = [headroom, 0, accounts.find { |a| a[:type] == :traditional }[:balance]].sort[1]

    perform_roth_conversion(conversion_amount, accounts)
  end

  def withdraw_for_spending(amount_needed, accounts)
    events = []
    remaining_need = amount_needed
    # Simplified withdrawal hierarchy (Taxable -> Traditional)
    [:taxable, :traditional].each do |type|
      break if remaining_need <= 0
      account = accounts.find { |a| a[:type] == type }
      next unless account && account[:balance] > 0

      pulled = [remaining_need, account[:balance]].min
      account[:balance] -= pulled
      remaining_need -= pulled

      taxable_ord = type == :traditional ? pulled : 0
      taxable_cg = type == :taxable ? pulled * (1 - account[:cost_basis_fraction]) : 0

      events << { type: :withdrawal, amount: pulled, taxable_ordinary: taxable_ord, taxable_capital_gains: taxable_cg }
    end
    events
  end

  def perform_roth_conversion(amount, accounts)
    return [] if amount <= 0
    trad_acct = accounts.find { |a| a[:type] == :traditional }
    roth_acct = accounts.find { |a| a[:type] == :roth }

    converted = [amount, trad_acct[:balance]].min
    trad_acct[:balance] -= converted
    roth_acct[:balance] += converted

    [{ type: :conversion, amount: converted, taxable_ordinary: converted, taxable_capital_gains: 0 }]
  end

  def calculate_taxes(ordinary_income, capital_gains)
    brackets = TAX_BRACKETS_2024['mfj']
    deduction = TAX_BRACKETS_2024['standard_deduction']['mfj']
    taxable_ord_after_deduction = [ordinary_income - deduction, 0].max

    # Calculate ordinary tax
    ord_tax = 0.0
    remaining_ord = taxable_ord_after_deduction
    brackets['ordinary'].reverse_each do |bracket|
      next if remaining_ord <= bracket['income']
      taxable_at_this_rate = remaining_ord - bracket['income']
      ord_tax += taxable_at_this_rate * bracket['rate']
      remaining_ord = bracket['income']
    end

    # Simplified capital gains tax (assumes it stacks on top)
    cg_tax = 0.0
    # This is a major simplification for clarity. A real model is more complex.
    if taxable_ord_after_deduction > brackets['capital_gains'][1]['income']
      cg_tax = capital_gains * brackets['capital_gains'][1]['rate']
    end

    total = ord_tax + cg_tax
    { federal: ord_tax, capital_gains: cg_tax, total: total }
  end

  def calculate_taxable_social_security(provisional_income, ss_total)
    return 0.0 if ss_total <= 0
    thresholds = TAX_BRACKETS_2024['mfj']['social_security_provisional_income']
    provisional = provisional_income + (ss_total * 0.5)

    return 0.0 if provisional <= thresholds['phase1_start']
    if provisional <= thresholds['phase2_start']
      return (provisional - thresholds['phase1_start']) * 0.5
    end

    phase1_taxable = (thresholds['phase2_start'] - thresholds['phase1_start']) * 0.5
    phase2_taxable = (provisional - thresholds['phase2_start']) * 0.85
    [phase1_taxable + phase2_taxable, ss_total * 0.85].min
  end

  def get_rmd(age, accounts)
    return 0.0 if age < 73 # Simplified RMD age
    rmd_divisor = { 73 => 26.5, 74 => 25.5, 75 => 24.6, 76 => 23.7, 77 => 22.9, 78 => 22.0, 79 => 21.2, 80 => 20.3, 81 => 19.5, 82 => 18.7, 83 => 17.9, 84 => 17.1, 85 => 16.3, 86 => 15.5, 87 => 14.8, 88 => 14.1, 89 => 13.4, 90 => 12.7, 91 => 12.0, 92 => 11.4, 93 => 10.8, 94 => 10.2, 95 => 9.6, 96 => 9.1, 97 => 8.6, 98 => 8.1, 99 => 7.6, 100 => 7.1 }
    divisor = rmd_divisor[age] || 7.1 # Fallback for older ages
    trad_balance = accounts.find { |a| a[:type] == :traditional }[:balance]
    rmd = trad_balance / divisor

    # RMD is a forced withdrawal
    accounts.find { |a| a[:type] == :traditional }[:balance] -= rmd
    rmd
  end

  def get_social_security_benefit(ss_source, age)
    age >= ss_source[:claiming_age] ? ss_source[:pia_annual] : 0.0
  end

  def grow_assets(accounts, growth_assumptions)
    accounts.each do |account|
      growth_rate = growth_assumptions[account[:type]] || 0
      account[:balance] *= (1 + growth_rate)
    end
  end

  def get_age(dob_string, year)
    dob = Date.parse(dob_string)
    year - dob.year - ((dob.month > Time.now.month || (dob.month == Time.now.month && dob.day > Time.now.day)) ? 1 : 0)
  end

  def aggregate_results(yearly_results)
    return { cumulative_taxes: 0, ending_net_worth: 0, total_gross_income: 0, total_expenses: 0 } if yearly_results.empty?
    {
      cumulative_taxes: yearly_results.sum { |r| r[:total_tax] }.round(0),
      ending_net_worth: yearly_results.last[:ending_net_worth].round(0),
      total_gross_income: yearly_results.sum { |r| r[:total_gross_income] }.round(0),
      total_expenses: yearly_results.sum { |r| r[:annual_expenses] }.round(0)
    }
  end
end

helpers do
  def run_simulation(strategy:, strategy_params: {}, profile:)
    Simulator.new.run(strategy: strategy, strategy_params: strategy_params, profile: profile)
  end

  def format_currency(number)
    "$#{number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end