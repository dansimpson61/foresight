require 'sinatra/base'
require 'slim'
require 'json'
require 'yaml'
require 'date'

# Load the domain model
require_relative 'lib/asset'
require_relative 'lib/traditional_ira'
require_relative 'lib/roth_ira'
require_relative 'lib/taxable_account'

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
        profile_data = payload[:profile] || payload
        profile = Foresight::Simple.symbolize_keys(profile_data) # Joyful fix: ensure all keys and values are symbolized correctly
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
        profile = Marshal.load(Marshal.dump(profile))
        yearly_results = []

        accounts = profile[:accounts].map do |acc|
          case acc[:type].to_sym
          when :traditional
            TraditionalIRA.new(balance: acc[:balance], owner: acc[:owner])
          when :roth
            RothIRA.new(balance: acc[:balance], owner: acc[:owner])
          when :taxable
            TaxableAccount.new(balance: acc[:balance], owner: acc[:owner], cost_basis_fraction: acc[:cost_basis_fraction] || 0.7)
          else
            nil
          end
        end.compact

        profile[:years_to_simulate].times do |i|
          current_year = profile[:start_year] + i
          annual_expenses = profile[:household][:annual_expenses]
          tax_brackets = get_tax_brackets_for_year(current_year)

          # --- Joyful Refactor: Multi-person logic ---
          ages = profile[:members].each_with_object({}) do |member, h|
            h[member[:name]] = get_age(member[:date_of_birth], current_year)
          end
          primary_person_age = ages[profile[:members].first[:name]]

          # A. Calculate Gross Income (Non-Discretionary)
          # Social Security for all members
          ss_benefit = profile[:income_sources].select { |s| s[:type] == :social_security }.sum do |ss_source|
            recipient_age = ages[ss_source[:recipient]]
            recipient_age >= ss_source[:claiming_age] ? ss_source[:pia_annual] : 0
          end

          # RMDs for all traditional accounts based on owner's age
          rmd = accounts.select { |a| a.is_a?(TraditionalIRA) }.sum do |trad_account|
            owner_age = ages[trad_account.owner]
            next 0 unless owner_age # Joyful fix: Skip RMD calc if owner is not a person (e.g., 'joint')

            rmd_amount = trad_account.calculate_rmd(owner_age)
            trad_account.withdraw(rmd_amount) # RMD is a forced withdrawal
            rmd_amount
          end

          gross_income_from_sources = ss_benefit + rmd

          # B. Determine Spending Shortfall and Withdrawals
          spending_shortfall = [annual_expenses - gross_income_from_sources, 0].max
          spending_withdrawals = withdraw_for_spending(spending_shortfall, accounts)

          # C. Determine Roth Conversion Amount
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

          taxable_ord_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_ordinary] }
          taxable_cg_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_capital_gains] }
          conversion_amount = conversion_events.sum { |e| e[:amount] }

          provisional_income = rmd + taxable_ord_from_withdrawals + conversion_amount
          final_taxable_ss = calculate_taxable_social_security(provisional_income, ss_benefit, tax_brackets)

          total_ordinary_income = rmd + final_taxable_ss + taxable_ord_from_withdrawals + conversion_amount
          taxes = calculate_taxes(total_ordinary_income, taxable_cg_from_withdrawals, tax_brackets)

          # E. Record results
          yearly_results << {
            year: current_year, age: primary_person_age,
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
            ending_net_worth: accounts.sum(&:balance).round(0),
            ending_balances: {
              traditional: (accounts.select { |a| a.is_a?(TraditionalIRA) }.sum(&:balance) || 0).round(0),
              roth: (accounts.select { |a| a.is_a?(RothIRA) }.sum(&:balance) || 0).round(0),
              taxable: (accounts.select { |a| a.is_a?(TaxableAccount) }.sum(&:balance) || 0).round(0)
            }
          }

          # F. Grow assets for next year
          grow_assets(accounts, profile[:growth_assumptions])
          profile[:household][:annual_expenses] *= (1 + profile[:inflation_rate])
        end

        { yearly: yearly_results, aggregate: aggregate_results(yearly_results) }
      end

      private

      def get_tax_brackets_for_year(year)
        applicable_year = TAX_BRACKETS.keys.select { |y| y <= year }.max || TAX_BRACKETS.keys.min
        TAX_BRACKETS[applicable_year]
      end

      def determine_conversion_events(strategy:, strategy_params:, accounts:, rmd:, ss_benefit:, spending_withdrawals:, tax_brackets:)
        return [] if strategy == :do_nothing

        taxable_ord_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_ordinary] }
        provisional_income_before_conversion = rmd + taxable_ord_from_withdrawals
        taxable_ss_before_conversion = calculate_taxable_social_security(provisional_income_before_conversion, ss_benefit, tax_brackets)
        taxable_income_before_conversion = rmd + taxable_ss_before_conversion + taxable_ord_from_withdrawals

        headroom = strategy_params[:ceiling] - taxable_income_before_conversion
        
        total_trad_balance = accounts.select { |a| a.is_a?(TraditionalIRA) }.sum(&:balance)
        return [] if total_trad_balance <= 0
        
        conversion_amount = [headroom, 0, total_trad_balance].sort[1]

        perform_roth_conversion(conversion_amount, accounts)
      end

      def withdraw_for_spending(amount_needed, accounts)
        events = []
        remaining_need = amount_needed
        withdrawal_order = [TaxableAccount, TraditionalIRA, RothIRA]

        withdrawal_order.each do |account_class|
          break if remaining_need <= 0
          # Find all accounts of the class type and withdraw from them. A more complex system might prioritize joint vs individual.
          accounts.select { |a| a.is_a?(account_class) }.each do |account|
            break if remaining_need <= 0
            next unless account.balance > 0

            pulled = account.withdraw(remaining_need)
            remaining_need -= pulled

            taxes = account.tax_on_withdrawal(pulled)

            events << {
              type: :withdrawal,
              amount: pulled,
              taxable_ordinary: taxes[:ordinary_income],
              taxable_capital_gains: taxes[:capital_gains]
            } if pulled > 0
          end
        end
        events
      end

      def perform_roth_conversion(amount, accounts)
        return [] if amount <= 0
        
        roth_acct = accounts.find { |a| a.is_a?(RothIRA) }
        return [] unless roth_acct

        trad_accounts = accounts.select { |a| a.is_a?(TraditionalIRA) }
        return [] if trad_accounts.empty?

        amount_to_convert = amount
        converted_total = 0

        # Simple strategy: pull from first available Traditional account.
        trad_accounts.each do |trad_acct|
          break if amount_to_convert <= 0

          converted_from_this_acct = trad_acct.withdraw(amount_to_convert)
          roth_acct.deposit(converted_from_this_acct)

          amount_to_convert -= converted_from_this_acct
          converted_total += converted_from_this_acct
        end

        [{ type: :conversion, amount: converted_total, taxable_ordinary: converted_total, taxable_capital_gains: 0 }] if converted_total > 0
      end

      def calculate_taxes(ordinary_income, capital_gains, tax_brackets)
        brackets = tax_brackets[:mfj]
        deduction = tax_brackets[:standard_deduction][:mfj]
        taxable_ord_after_deduction = [ordinary_income - deduction, 0].max

        ord_tax = 0.0
        remaining_ord = taxable_ord_after_deduction
        brackets[:ordinary].reverse_each do |bracket|
          next if remaining_ord <= bracket[:income]
          taxable_at_this_rate = remaining_ord - bracket[:income]
          ord_tax += taxable_at_this_rate * bracket[:rate]
          remaining_ord = bracket[:income]
        end

        cg_tax = 0.0
        if taxable_ord_after_deduction > brackets[:capital_gains][1][:income]
          cg_tax = capital_gains * brackets[:capital_gains][1][:rate]
        elsif taxable_ord_after_deduction > brackets[:capital_gains][0][:income]
          cg_tax = capital_gains * 0.15
        end

        total = ord_tax + cg_tax
        { federal: ord_tax, capital_gains: cg_tax, total: total }
      end

      def calculate_taxable_social_security(provisional_income, ss_total, tax_brackets)
        return 0.0 if ss_total <= 0
        thresholds = tax_brackets[:mfj][:social_security_provisional_income]
        provisional = provisional_income + (ss_total * 0.5)
        return 0.0 if provisional <= thresholds[:phase1_start]
        
        if provisional <= thresholds[:phase2_start]
          return (provisional - thresholds[:phase1_start]) * 0.5
        end

        phase1_taxable = (thresholds[:phase2_start] - thresholds[:phase1_start]) * 0.5
        phase2_taxable = (provisional - thresholds[:phase2_start]) * 0.85
        [phase1_taxable + phase2_taxable, ss_total * 0.85].min
      end

      def grow_assets(accounts, growth_assumptions)
        accounts.each do |account|
          type_key = case account
                     when TraditionalIRA then :traditional
                     when RothIRA then :roth
                     when TaxableAccount then :taxable
                     else :cash
                     end
          growth_rate = growth_assumptions[type_key] || 0
          account.grow(growth_rate)
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