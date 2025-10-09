require 'sinatra/base'
require 'slim'
require 'json'
require 'yaml'
require 'date'
require 'securerandom'

# Load the domain model
require_relative 'lib/helpers/ui_helpers'
require_relative 'lib/asset'
require_relative 'lib/traditional_ira'
require_relative 'lib/roth_ira'
require_relative 'lib/taxable_account'
require_relative 'lib/policies/tax_policy'
require_relative 'lib/policies/withdrawal_policy'
  require_relative 'lib/flows/flow'
  require_relative 'lib/flows/rmd_flow'
  require_relative 'lib/flows/conversion_flow'
  require_relative 'lib/flows/social_security_flow'
  require_relative 'lib/decisions/fill_to_bracket_decision'
  require_relative 'lib/decisions/claim_ss_decision'
  require_relative 'lib/persistence'

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

    # Deep merge for Hash/Array that preserves defaults unless explicitly overridden.
    # Arrays: if incoming array is nil or empty, keep base; otherwise replace (we avoid partial merging arrays for simplicity).
    def self.deep_merge(base, overrides)
      return base if overrides.nil?
      case [base, overrides]
      in [Hash => h1, Hash => h2]
        (h1.keys | h2.keys).each_with_object({}) do |key, acc|
          acc[key] = deep_merge(h1[key], h2[key])
        end
      in [Array => a1, Array => a2]
        a2.nil? || a2.empty? ? a1 : a2
      else
        overrides.nil? ? base : overrides
      end
    end

    ROOT_DIR = File.expand_path(__dir__)
    DEFAULT_PROFILE = symbolize_keys(YAML.load_file(File.join(ROOT_DIR, 'profile.yml')))
    TAX_BRACKETS   = symbolize_keys(YAML.load_file(File.join(ROOT_DIR, 'tax_brackets.yml')))

    class UI < Sinatra::Base
  set :root, File.expand_path('..', __FILE__)
      set :views, File.expand_path('views', __dir__)
      set :public_folder, File.expand_path('public', __dir__)
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || SecureRandom.hex(32)
      enable :static
      helpers Foresight::Simple::UIHelpers

      # --- The Application ---
      get '/' do
        # Single source of truth: global defaults (or baked-in if none).
        global_defaults = Persistence.load('defaults')
        effective_profile = Foresight::Simple.deep_merge(
          DEFAULT_PROFILE,
          global_defaults && global_defaults[:profile]
        )
        effective_strategy = (global_defaults && global_defaults[:strategy]) || :fill_to_bracket
        effective_strategy_params = (global_defaults && global_defaults[:strategy_params]) || { ceiling: 94_300 }

        # Run simulations with the effective (persisted or default) profile
        do_nothing_results = run_simulation(strategy: :do_nothing, profile: effective_profile)
        fill_bracket_results = run_simulation(
          strategy: effective_strategy, 
          strategy_params: effective_strategy_params, 
          profile: effective_profile
        )

        # Pass results and complete profile to the view
        slim :index, locals: {
          profile: effective_profile,
          strategy: effective_strategy,
          strategy_params: effective_strategy_params,
          do_nothing_results: do_nothing_results,
          fill_bracket_results: fill_bracket_results
        }
      end

      # Reset to global defaults (stateless per session)
      post '/reset_defaults' do
        content_type :json
        { status: 'ok' }.to_json
      end

      # Save the provided profile and simulation params as the global defaults
      post '/save_defaults' do
        content_type :json
        payload = JSON.parse(request.body.read, symbolize_names: true)
  incoming = Foresight::Simple.symbolize_keys(payload[:profile] || {})
  profile = Foresight::Simple.deep_merge(DEFAULT_PROFILE, incoming)
        strategy = (payload[:strategy] || :fill_to_bracket).to_sym
        strategy_params = payload[:strategy_params] || { ceiling: 94_300 }
        payload_to_save = { profile: profile, strategy: strategy, strategy_params: strategy_params }
        Persistence.save('defaults', payload_to_save)
        # Mirror to legacy path outside of test to maximize survivability across env changes
        Persistence.save_legacy('defaults', payload_to_save) unless Persistence.env == 'test'
        { status: 'ok' }.to_json
      end

      # Clear global defaults entirely (used by tests and recovery)
      post '/clear_defaults' do
        content_type :json
        ok = Persistence.delete('defaults')
        { status: ok ? 'ok' : 'error' }.to_json
      end

      # Lightweight Mermaid viewer for object hierarchy diagrams
      get '/diagrams' do
        # Prefer repo-root docs path: ../docs/Object_Hierarchy.md relative to simple/
        candidates = [
          File.expand_path('../docs/Object_Hierarchy.md', __dir__),
          File.expand_path('../../docs/Object_Hierarchy.md', __dir__)
        ]
        path = candidates.find { |p| File.exist?(p) }
        content = if path && File.file?(path)
          File.read(path)
        else
          "# Diagrams\n\nNo diagram file found."
        end
        slim :diagrams, locals: { markdown: content }
      end

      # Tokens & utilities page
      get '/tokens' do
        slim :tokens
      end

      # Blank canvas for experiments
      get '/playground' do
        slim :playground
      end

      # Back-compat for static file path
      get '/tokens.html' do
        redirect to('/tokens')
      end

      # Redirect ICO favicon requests to our SVG icon to avoid 404s
      get '/favicon.ico' do
        redirect to('/favicon.svg')
      end

      post '/run' do
        content_type :json
        payload = JSON.parse(request.body.read, symbolize_names: true)

        # Extract profile, strategy, and parameters
        # Handle both old format (just profile) and new format (with strategy/params)
        profile_data = payload[:profile] || payload
  raw_profile = Foresight::Simple.symbolize_keys(profile_data)
  profile = Foresight::Simple.deep_merge(DEFAULT_PROFILE, raw_profile)
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
          "$#{number.to_s.reverse.gsub(/(\\d{3})(?=\\d)/, '\\1,').reverse}"
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
          flows_applied = []

          # --- Joyful Refactor: Multi-person logic ---
          ages = profile[:members].each_with_object({}) do |member, h|
            h[member[:name]] = get_age(member[:date_of_birth], current_year)
          end
          primary_person_age = ages[profile[:members].first[:name]]

          # A. Calculate Gross Income (Non-Discretionary)
          # Social Security for all members via decision + flow (pure, additive)
          ss_flows = Decisions::ClaimSSDecision.decide_for_year(
            ages: ages,
            income_sources: profile[:income_sources]
          )
          ss_benefit = ss_flows.sum(&:amount)
          ss_flows.each do |flow|
            flows_applied << { type: :social_security, amount: flow.amount, tax_character: flow.tax_character, recipient: flow.recipient }
            flow.apply(nil)
          end

          # RMDs for all traditional accounts based on owner's age
          rmd = accounts.select { |a| a.is_a?(TraditionalIRA) }.sum do |trad_account|
            owner_age = ages[trad_account.owner] || primary_person_age
            next 0 unless owner_age # Skip RMD calc if no age context at all

            rmd_amount = trad_account.calculate_rmd(owner_age)
            next 0 if rmd_amount <= 0
            # Use Flow abstraction to apply the RMD and trace it
            rmd_flow = RMDFlow.new(amount: rmd_amount, account: trad_account)
            flows_applied << { type: :rmd, amount: rmd_amount, tax_character: rmd_flow.tax_character, owner: trad_account.owner }
            rmd_flow.apply(nil)
            rmd_amount
          end

          gross_income_from_sources = ss_benefit + rmd

          # B. Determine Spending Shortfall and Withdrawals
          spending_shortfall = [annual_expenses - gross_income_from_sources, 0].max
          custom_order = profile.dig(:household, :withdrawal_hierarchy)
          spending_withdrawals = WithdrawalPolicy.withdraw_for_spending(spending_shortfall, accounts, order: custom_order)
          # Trace withdrawals as flows for observability (additive-only)
          spending_withdrawals.each do |e|
            flows_applied << {
              type: :withdrawal,
              amount: e[:amount],
              tax_character: (e[:taxable_ordinary].to_f > 0 ? :ordinary : (e[:taxable_capital_gains].to_f > 0 ? :capital_gains : :none))
            }
          end

          # C. Determine Roth Conversion Amount
          conversion_events = determine_conversion_events(
            strategy: strategy,
            strategy_params: strategy_params,
            accounts: accounts,
            rmd: rmd,
            ss_benefit: ss_benefit,
            spending_withdrawals: spending_withdrawals,
            tax_brackets: tax_brackets,
            flows_applied: flows_applied
          )

          # D. Finalize Financial Picture for the Year
          withdrawals_for_spending_amount = spending_withdrawals.sum { |e| e[:amount] }
          total_gross_income = gross_income_from_sources + withdrawals_for_spending_amount

          taxable_ord_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_ordinary] }
          taxable_cg_from_withdrawals = spending_withdrawals.sum { |e| e[:taxable_capital_gains] }
          conversion_amount = conversion_events.sum { |e| e[:amount] }

          provisional_income = rmd + taxable_ord_from_withdrawals + conversion_amount
          final_taxable_ss = TaxPolicy.taxable_social_security(provisional_income, ss_benefit, tax_brackets)

          total_ordinary_income = rmd + final_taxable_ss + taxable_ord_from_withdrawals + conversion_amount
          taxes = TaxPolicy.calculate_taxes(total_ordinary_income, taxable_cg_from_withdrawals, tax_brackets)

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
            },
            flows_applied: flows_applied
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

  def determine_conversion_events(strategy:, strategy_params:, accounts:, rmd:, ss_benefit:, spending_withdrawals:, tax_brackets:, flows_applied: [])
        return [] if strategy == :do_nothing

    ceiling = strategy_params[:ceiling]
    amount = Decisions::FillToBracketDecision.propose_conversion_amount(
      rmd: rmd,
      ss_benefit: ss_benefit,
      spending_withdrawals: spending_withdrawals,
      tax_brackets: tax_brackets,
      accounts: accounts,
      ceiling: ceiling
    )

    perform_roth_conversion(amount, accounts, flows_applied: flows_applied)
      end

      # WithdrawalPolicy now provides withdrawal behavior

      def perform_roth_conversion(amount, accounts, flows_applied: [])
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

          # Use Flow abstraction to apply conversion between accounts
          before_trad = trad_acct.balance
          conv_flow = ConversionFlow.new(amount: amount_to_convert, from_account: trad_acct, to_account: roth_acct)
          conv_flow.apply(nil)
          converted_from_this_acct = before_trad - trad_acct.balance
          if converted_from_this_acct > 0
            flows_applied << { type: :conversion, amount: converted_from_this_acct, tax_character: conv_flow.tax_character, from: trad_acct.owner, to: roth_acct.owner }
          end

          amount_to_convert -= converted_from_this_acct
          converted_total += converted_from_this_acct
        end

        [{ type: :conversion, amount: converted_total, taxable_ordinary: converted_total, taxable_capital_gains: 0 }] if converted_total > 0
      end

      # TaxPolicy now provides tax calculations

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