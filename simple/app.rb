# An Ode to Joy: A Radically Simplified Financial Simulator
# All logic, data, and routing are contained in this single file.

require 'sinatra'
require 'slim'
require 'json'

# --- Configuration ---
set :port, 9293
set :bind, '0.0.0.0'
set :views, File.dirname(__FILE__) + '/views'
set :public_folder, File.dirname(__FILE__) + '/public'

# --- Hardcoded Financial Profile (The Single Purpose) ---
# This hash represents the complete financial state of our user.
# It replaces the need for a complex data entry UI.
FINANCIAL_PROFILE = {
  start_year: 2024,
  years_to_simulate: 30,
  inflation_rate: 0.03,
  growth_assumptions: {
    traditional: 0.04,
    roth: 0.05,
    taxable: 0.03,
    cash: 0.01
  },
  household: {
    filing_status: 'mfj', # married filing jointly
    state: 'NY',
    annual_expenses: 100_000,
    emergency_fund_floor: 50_000,
    withdrawal_hierarchy: [:taxable, :traditional, :roth]
  },
  members: [
    { name: 'Pat', date_of_birth: '1964-05-01' }
  ],
  accounts: [
    { type: :traditional, owner: 'Pat', balance: 1_000_000 },
    { type: :roth, owner: 'Pat', balance: 250_000 },
    { type: :taxable, owner: 'Pat', balance: 500_000, cost_basis_fraction: 0.6 },
    { type: :cash, owner: 'Pat', balance: 100_000 }
  ],
  income_sources: [
    {
      type: :social_security,
      recipient: 'Pat',
      pia_annual: 40_000, # Primary Insurance Amount at Full Retirement Age
      claiming_age: 70
    }
  ]
}.freeze

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
  # Run both simulations
  do_nothing_results = run_simulation(strategy: :do_nothing)
  fill_bracket_results = run_simulation(strategy: :fill_to_bracket, strategy_params: { ceiling: 94_300 }) # Fill to top of 22% bracket

  # Pass results to the view
  slim :index, locals: {
    do_nothing_results: do_nothing_results,
    fill_bracket_results: fill_bracket_results
  }
end

helpers do
  # --- Core Simulation Logic ---
  def run_simulation(strategy:, strategy_params: {})
    # Deep copy the profile to prevent mutation between runs
    profile = Marshal.load(Marshal.dump(FINANCIAL_PROFILE))
    yearly_results = []
    accounts = profile[:accounts]

    profile[:years_to_simulate].times do |i|
      current_year = profile[:start_year] + i
      person = profile[:members].first # Simplify for single person
      age = get_age(person[:date_of_birth], current_year)

      # 1. Baseline Income
      ss_benefit = get_social_security_benefit(profile[:income_sources].first, age)
      rmd = get_rmd(age, accounts)

      # Provisional income for SS taxability
      provisional_income = rmd
      taxable_ss_baseline = calculate_taxable_social_security(provisional_income, ss_benefit)
      base_taxable_income = rmd + taxable_ss_baseline

      # 2. Spending Needs
      gross_income = ss_benefit + rmd
      # Estimate taxes on baseline income to see if we have a shortfall
      estimated_taxes = calculate_taxes(base_taxable_income, 0)[:total]
      net_income = gross_income - estimated_taxes
      spending_shortfall = [profile[:household][:annual_expenses] - net_income, 0].max

      # 3. Apply Strategy (produces events for conversions and withdrawals)
      strategy_events = apply_strategy(
        strategy: strategy,
        params: strategy_params,
        accounts: accounts,
        base_taxable_income: base_taxable_income,
        spending_shortfall: spending_shortfall,
        ss_benefit: ss_benefit
      )

      # 4. Finalize Income & Taxes for the Year
      taxable_from_events = strategy_events.sum { |e| e[:taxable_ordinary] }
      capital_gains_from_events = strategy_events.sum { |e| e[:taxable_capital_gains] }

      final_provisional_income = provisional_income + taxable_from_events + capital_gains_from_events
      final_taxable_ss = calculate_taxable_social_security(final_provisional_income, ss_benefit)

      total_ordinary_income = rmd + final_taxable_ss + taxable_from_events
      taxes = calculate_taxes(total_ordinary_income, capital_gains_from_events)

      # 5. Record results and Grow Assets
      yearly_results << {
        year: current_year,
        age: age,
        income_breakdown: { rmd: rmd, taxable_ss: final_taxable_ss, conversions: strategy_events.select{|e| e[:type] == :conversion}.sum{|e| e[:amount]}, withdrawals_ord: strategy_events.select{|e| e[:type] == :withdrawal}.sum{|e| e[:taxable_ordinary]} },
        total_tax: taxes[:total],
        ending_net_worth: accounts.sum { |a| a[:balance] }
      }

      grow_assets(accounts, profile[:growth_assumptions])
      profile[:household][:annual_expenses] *= (1 + profile[:inflation_rate])
    end

    { yearly: yearly_results, aggregate: aggregate_results(yearly_results) }
  end

  private

  # --- Simulation Helpers ---

  def apply_strategy(strategy:, params:, accounts:, base_taxable_income:, spending_shortfall:, ss_benefit:)
    case strategy
    when :do_nothing
      withdraw_for_spending(spending_shortfall, accounts)
    when :fill_to_bracket
      # First, cover spending. This might generate taxable income.
      spending_events = withdraw_for_spending(spending_shortfall, accounts)
      taxable_from_spending = spending_events.sum { |e| e[:taxable_ordinary] }

      # Then, calculate conversion amount needed to fill the bracket
      current_taxable = base_taxable_income + taxable_from_spending
      provisional_after_spending = base_taxable_income - calculate_taxable_social_security(base_taxable_income, ss_benefit) + taxable_from_spending

      # Simplified headroom calculation
      headroom = params[:ceiling] - current_taxable
      conversion_amount = [headroom, 0, accounts.find { |a| a[:type] == :traditional }[:balance]].sort[1]

      conversion_events = perform_roth_conversion(conversion_amount, accounts)
      spending_events + conversion_events
    end
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
    return { cumulative_taxes: 0, ending_net_worth: 0 } if yearly_results.empty?
    {
      cumulative_taxes: yearly_results.sum { |r| r[:total_tax] }.round(0),
      ending_net_worth: yearly_results.last[:ending_net_worth].round(0)
    }
  end

  def format_currency(number)
    "$#{number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
end