require 'sinatra/base'
require 'slim'
require 'json'
require 'yaml'
require 'date'

module Foresight
  module Simple
    # --- Default Financial Profile ---
    # Loaded from an external YAML file for easier configuration.
    def self.symbolize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), result|
          new_key = k.is_a?(String) ? k.to_sym : k
          result[new_key] = symbolize_keys(v)
        end
      when Array
        obj.map { |v| symbolize_keys(v) }
      else
        obj
      end
    end

    ROOT_DIR = File.expand_path(__dir__)
    DEFAULT_PROFILE = symbolize_keys(YAML.load_file(File.join(ROOT_DIR, 'profile.yml')))
    TAX_BRACKETS   = symbolize_keys(YAML.load_file(File.join(ROOT_DIR, 'tax_brackets.yml')))

    class UI < Sinatra::Base
      set :root, File.expand_path('..', __FILE__)
      set :views, File.expand_path('views', __dir__)
      set :public_folder, File.expand_path('public', __dir__)
      enable :static

      # --- The Application ---
      get '/' do
        # Run simulations with the default profile for the initial page load
        do_nothing_results = run_simulation(strategy: :do_nothing, profile: DEFAULT_PROFILE)
        fill_bracket_results = run_simulation(
          strategy: :fill_to_bracket, 
          strategy_params: { ceiling: 94_300 }, 
          profile: DEFAULT_PROFILE
        )

        # Pass results and complete profile to the view
        slim :index, locals: {
          profile: DEFAULT_PROFILE,
          do_nothing_results: do_nothing_results,
          fill_bracket_results: fill_bracket_results
        }
      end

      post '/run' do
        content_type :json
        payload = JSON.parse(request.body.read, symbolize_names: true)

        # Extract profile, strategy, and parameters
        # Handle both old format (just profile) and new format (with strategy/params)
        profile = payload[:profile] || payload
        strategy = payload[:strategy] || :fill_to_bracket
        strategy_params = payload[:strategy_params] || { ceiling: 94_300 }

        # Run both simulations to maintain consistency with UI expectations
        do_nothing_results = run_simulation(strategy: :do_nothing, profile: profile)
        fill_bracket_results = run_simulation(
          strategy: strategy.to_sym, 
          strategy_params: strategy_params, 
          profile: profile
        )

        {
          do_nothing_results: do_nothing_results,
          fill_bracket_results: fill_bracket_results,
          profile: profile  # Echo back the profile for consistency
        }.to_json
      end

      helpers do
        def run_simulation(strategy:, strategy_params: {}, profile:)
          Simulator.new.run(strategy: strategy, strategy_params: strategy_params, profile: profile)
        end

        def format_currency(number)
          "$#{number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
        end
      end
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
          tax_brackets = get_tax_brackets_for_year(current_year)

          # A. Calculate Gross Income (Non-Discretionary)
          ss_source = profile[:income_sources].find { |s| s[:type] == :social_security }
          ss_benefit = get_social_security_benefit(ss_source, age)
          rmd = get_rmd(age, accounts)
          gross_income_from_sources = ss_benefit + rmd

          # B. Determine Spending Shortfall and Withdrawals
          # This is a simplification. A real model would account for taxes on withdrawals.
          # For clarity, we assume withdrawals are made to cover the gap after income is received.
          spending_shortfall = [annual_expenses - gross_income_from_sources, 0].max
          spending_withdrawals = withdraw_for_spending(spending_shortfall, accounts)

          # C. Determine Roth Conversion Amount
          # NOTE: This uses a simplified approach that approximates the impact of conversions
          # on Social Security taxation. A more robust model would iteratively solve for
          # the optimal conversion amount, since conversions increase provisional income
          # which can increase the taxable portion of Social Security benefits.
          conversion_events = determine_conversion_events(
            strategy: strategy,
            strategy_params: strategy_params,
            accounts: accounts,
            rmd: rmd,
            ss_benefit: ss_benefit,
            spending_withdrawals: spending_withdrawals,
            tax_brackets: tax_brackets
          )

          # D. Finalize Financial Picture for the Year
          withdrawals_for_spending_amount = spending_withdrawals.sum { |e| e[:amount] }
          total_gross_income = gross_income_from_sources + withdrawals_for_spending_amount

          # Finalize Taxable Income
          taxable_ord_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_ordinary] }
          taxable_cg_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_capital_gains] }
          conversion_amount = conversion_events.sum { |e| e[:amount] }

          provisional_income = rmd + taxable_ord_from_withdrawals + conversion_amount
          final_taxable_ss = calculate_taxable_social_security(provisional_income, ss_benefit, tax_brackets)

          total_ordinary_income = rmd + final_taxable_ss + taxable_ord_from_withdrawals + conversion_amount
          taxes = calculate_taxes(total_ordinary_income, taxable_cg_from_withdrawals, tax_brackets)

          # E. Record results
          yearly_results << {
            year: current_year, age: age,
            annual_expenses: annual_expenses.round(0),
            total_gross_income: total_gross_income.round(0),
            income_sources: { 
              social_security: ss_benefit.round(0), 
              rmd: rmd.round(0), 
              withdrawals: withdrawals_for_spending_amount.round(0) 
            },
            taxable_income_breakdown: {
              rmd: rmd.round(0), 
              taxable_ss: final_taxable_ss.round(0), 
              conversions: conversion_amount.round(0),
              taxable_withdrawals: taxable_ord_from_withdrawals.round(0), 
              capital_gains: taxable_cg_from_withdrawals.round(0)
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

      def get_tax_brackets_for_year(year)
        # Find the latest year in our data that is less than or equal to the current year
        # or fall back to the earliest year if the simulation starts before our data.
        applicable_year = TAX_BRACKETS.keys.select { |y| y <= year }.max || TAX_BRACKETS.keys.min
        TAX_BRACKETS[applicable_year]
      end

      def determine_conversion_events(strategy:, strategy_params:, accounts:, rmd:, ss_benefit:, spending_withdrawals:, tax_brackets:)
        return [] if strategy == :do_nothing

        # This is the core logic for the "fill_to_bracket" strategy
        taxable_ord_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_ordinary] }

        # This is the key calculation: determine the taxable income *before* the discretionary conversion
        provisional_income_before_conversion = rmd + taxable_ord_from_withdrawals
        taxable_ss_before_conversion = calculate_taxable_social_security(provisional_income_before_conversion, ss_benefit, tax_brackets)
        taxable_income_before_conversion = rmd + taxable_ss_before_conversion + taxable_ord_from_withdrawals

        headroom = strategy_params[:ceiling] - taxable_income_before_conversion

        # NOTE: This is a simplification. A more robust model would iteratively solve for the
        # ideal conversion amount, since conversions increase provisional income which can
        # increase the taxable portion of Social Security benefits, reducing actual headroom.
        # This approximation works well when conversions are modest relative to the bracket ceiling.
        
        # Guard against missing Traditional IRA account
        trad_account = accounts.find { |a| a[:type] == :traditional }
        return [] unless trad_account
        
        conversion_amount = [headroom, 0, trad_account[:balance]].sort[1]

        perform_roth_conversion(conversion_amount, accounts)
      end

      def withdraw_for_spending(amount_needed, accounts)
        events = []
        remaining_need = amount_needed
        # Simplified withdrawal hierarchy (Taxable -> Traditional -> Roth)
        [:taxable, :traditional, :roth].each do |type|
          break if remaining_need <= 0
          account = accounts.find { |a| a[:type] == type }
          next unless account && account[:balance] > 0

          pulled = [remaining_need, account[:balance]].min
          account[:balance] -= pulled
          remaining_need -= pulled

          # Determine taxability based on account type
          taxable_ord = type == :traditional ? pulled : 0
          # Use cost_basis_fraction if available, default to 0 if missing
          cost_basis = type == :taxable ? (account[:cost_basis_fraction] || 0) : 0
          taxable_cg = type == :taxable ? pulled * (1 - cost_basis) : 0

          events << { 
            type: :withdrawal, 
            amount: pulled, 
            taxable_ordinary: taxable_ord, 
            taxable_capital_gains: taxable_cg 
          }
        end
        events
      end

      def perform_roth_conversion(amount, accounts)
        return [] if amount <= 0
        
        trad_acct = accounts.find { |a| a[:type] == :traditional }
        roth_acct = accounts.find { |a| a[:type] == :roth }
        
        # Guard against missing accounts
        return [] unless trad_acct && roth_acct

        converted = [amount, trad_acct[:balance]].min
        trad_acct[:balance] -= converted
        roth_acct[:balance] += converted

        [{ type: :conversion, amount: converted, taxable_ordinary: converted, taxable_capital_gains: 0 }]
      end

      def calculate_taxes(ordinary_income, capital_gains, tax_brackets)
        brackets = tax_brackets[:mfj]
        deduction = tax_brackets[:standard_deduction][:mfj]
        taxable_ord_after_deduction = [ordinary_income - deduction, 0].max

        # Calculate ordinary tax
        ord_tax = 0.0
        remaining_ord = taxable_ord_after_deduction
        brackets[:ordinary].reverse_each do |bracket|
          next if remaining_ord <= bracket[:income]
          taxable_at_this_rate = remaining_ord - bracket[:income]
          ord_tax += taxable_at_this_rate * bracket[:rate]
          remaining_ord = bracket[:income]
        end

        # Simplified capital gains tax
        # NOTE: This is a major simplification. In reality, capital gains "stack" on top of
        # ordinary income, and the bracket thresholds depend on the total. This simplified
        # version applies a flat rate based on ordinary income position, which approximates
        # the effect but may not be precisely accurate for all scenarios.
        cg_tax = 0.0
        if taxable_ord_after_deduction > brackets[:capital_gains][1][:income]
          cg_tax = capital_gains * brackets[:capital_gains][1][:rate]
        elsif taxable_ord_after_deduction > brackets[:capital_gains][0][:income]
          # In reality, we'd need to calculate how much CG fits in the 0% bracket
          # and how much spills into the 15% bracket. This is simplified.
          cg_tax = capital_gains * 0.15
        end

        total = ord_tax + cg_tax
        { federal: ord_tax, capital_gains: cg_tax, total: total }
      end

      def calculate_taxable_social_security(provisional_income, ss_total, tax_brackets)
        return 0.0 if ss_total <= 0
        thresholds = tax_brackets[:mfj][:social_security_provisional_income]
        
        # Provisional income includes 50% of Social Security benefits
        provisional = provisional_income + (ss_total * 0.5)

        return 0.0 if provisional <= thresholds[:phase1_start]
        
        if provisional <= thresholds[:phase2_start]
          # 50% of SS is taxable in phase 1
          return (provisional - thresholds[:phase1_start]) * 0.5
        end

        # In phase 2, up to 85% of SS can be taxable
        phase1_taxable = (thresholds[:phase2_start] - thresholds[:phase1_start]) * 0.5
        phase2_taxable = (provisional - thresholds[:phase2_start]) * 0.85
        [phase1_taxable + phase2_taxable, ss_total * 0.85].min
      end

      def get_rmd(age, accounts)
        return 0.0 if age < 73 # Simplified RMD age (actual varies by birth year)
        
        # Find Traditional IRA account
        trad_account = accounts.find { |a| a[:type] == :traditional }
        return 0.0 unless trad_account  # Guard against missing account
        
        # IRS Uniform Lifetime Table divisors
        rmd_divisor = { 
          73 => 26.5, 74 => 25.5, 75 => 24.6, 76 => 23.7, 77 => 22.9, 
          78 => 22.0, 79 => 21.2, 80 => 20.3, 81 => 19.5, 82 => 18.7, 
          83 => 17.9, 84 => 17.1, 85 => 16.3, 86 => 15.5, 87 => 14.8, 
          88 => 14.1, 89 => 13.4, 90 => 12.7, 91 => 12.0, 92 => 11.4, 
          93 => 10.8, 94 => 10.2, 95 => 9.6, 96 => 9.1, 
          97 => 8.6, 98 => 8.1, 99 => 7.6, 100 => 7.1 
        }
        divisor = rmd_divisor[age] || 7.1 # Fallback for older ages
        trad_balance = trad_account[:balance]
        rmd = trad_balance / divisor

        # RMD is a forced withdrawal
        trad_account[:balance] -= rmd
        rmd
      end

      def get_social_security_benefit(ss_source, age)
        return 0.0 unless ss_source  # Guard against nil
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
  end
end