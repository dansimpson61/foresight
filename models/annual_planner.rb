# frozen_string_literal: true

require_relative './money'

module Foresight
  class AnnualPlanner
    StrategyResult = Struct.new(
      :strategy_name,
      :year,
      :base_taxable_income,
      :roth_conversion_requested,
      :actual_roth_conversion,
      :taxable_income_after_conversion,
      :magi,
      :after_tax_cash_before_spending_withdrawals,
      :remaining_spending_need,
      :withdrawals,
      :federal_tax,
      :capital_gains_tax,
      :state_tax,
      :irmaa_part_b,
      :effective_tax_rate,
      :ss_taxable_post,
      :ss_taxable_increase,
      :conversion_incremental_tax,
      :conversion_incremental_marginal_rate,
      :narration,
      keyword_init: true
    )

    attr_reader :household, :tax_year

    def initialize(household:, tax_year:)
      @household = household
      @tax_year = tax_year
    end

    def run(strategies)
      strategies = Array(strategies)
      base_snapshot = snapshot_accounts
      base_income = compute_base_income
      strategies.map do |strategy|
        restore_accounts(base_snapshot)
        execute_for_strategy(strategy, base_income)
      end
    end

    def run_comparison
      run([
        ConversionStrategies::NoConversion.new,
        ConversionStrategies::BracketFill.new
      ])
    end

    def generate_strategy(strategy)
      base_income = compute_base_income
      execute_for_strategy(strategy, base_income)
    end

    private

    def compute_base_income
      pension_gross = Money.new(0)
      pension_taxable = Money.new(0)
      @household.pensions.each do |p|
        pension_gross += p.annual_gross
        pension_taxable += p.annual_gross
      end
      rmds = @household.traditional_iras.sum { |acct| acct.calculate_rmd(acct.owner.age_in(@tax_year.year)) }
      ss_total = @household.social_security_benefits.sum { |b| b.annual_benefit_for(@tax_year.year) }
      pre_ss_other_income = pension_taxable + rmds
      ss_taxable_baseline = taxable_social_security(ss_total, other_income: pre_ss_other_income)
      gross_income_baseline = pension_gross + ss_total + rmds
      baseline_taxable = pre_ss_other_income + ss_taxable_baseline
      after_tax_cash = pension_gross + ss_total + rmds
      {
        pension_gross: pension_gross,
        pension_taxable: pension_taxable,
        rmds: rmds,
        ss_total: ss_total,
        pre_ss_other_income: pre_ss_other_income,
        ss_taxable_baseline: ss_taxable_baseline,
        gross_income: gross_income_baseline,
        taxable_income: baseline_taxable,
        after_tax_cash: after_tax_cash
      }
    end

    def taxable_social_security(ss_total, other_income: Money.new(0))
      # Provisional income thresholds vary by filing status
      if @household.filing_status == 'MFJ'
        base_thresh = Money.new(32_000)
        addl_thresh = Money.new(44_000)
      else
        base_thresh = Money.new(25_000)
        addl_thresh = Money.new(34_000)
      end
      provisional = other_income + (ss_total * 0.5)
      if provisional.amount <= base_thresh.amount
        Money.new(0)
      elsif provisional.amount <= addl_thresh.amount
        (provisional - base_thresh) * 0.5
      else
        base = (addl_thresh - base_thresh) * 0.5
        excess = provisional - addl_thresh
        [(excess * 0.85) + base, ss_total * 0.85].min
      end
    end

    def execute_for_strategy(strategy, base_income)
      baseline_taxable = base_income[:taxable_income]
      requested = strategy.conversion_amount(household: @household, tax_year: @tax_year, base_taxable_income: baseline_taxable)
      remaining = requested
      actual = Money.new(0)
      if remaining.positive?
        @household.traditional_iras.each do |acct|
          break if remaining.amount <= 0
          slice = [acct.balance, remaining.amount].min
          res = acct.convert_to_roth(slice)
          remaining -= res[:converted]
          actual += res[:converted]
        end
      end

      ss_taxable_post = taxable_social_security(base_income[:ss_total], other_income: base_income[:pre_ss_other_income] + actual)
      taxable_after_conv = base_income[:pre_ss_other_income] + actual + ss_taxable_post
      ss_taxable_increase = ss_taxable_post - base_income[:ss_taxable_baseline]
      after_tax_cash = base_income[:after_tax_cash]
      remaining_need = [@household.target_spending_after_tax - after_tax_cash.amount, 0].max
      withdrawals = allocate_spending_gap(remaining_need, taxable_after_conv)
      total_taxable_ordinary = taxable_after_conv + withdrawals[:added_ordinary_taxable]
      ordinary_taxable_after_std_ded = [total_taxable_ordinary.amount - @tax_year.standard_deduction.amount, 0].max

      federal_tax_money = @tax_year.tax_on_ordinary(Money.new(ordinary_taxable_after_std_ded))
      cap_gains_tax_money = @tax_year.tax_on_ltcg(withdrawals[:capital_gains_taxable], ordinary_taxable_income: Money.new(ordinary_taxable_after_std_ded))
      total_tax_money = federal_tax_money + cap_gains_tax_money

      ny_std = @tax_year.respond_to?(:ny_standard_deduction) ? @tax_year.ny_standard_deduction(@household.filing_status) : Money.new(0)
      ny_taxable = [total_taxable_ordinary.amount - ny_std.amount, 0].max
      state_tax_money = @tax_year.respond_to?(:ny_tax_on_income) ? @tax_year.ny_tax_on_income(Money.new(ny_taxable), filing_status: @household.filing_status) : Money.new(0)

      magi = total_taxable_ordinary + withdrawals[:capital_gains_taxable]
      irmaa_part_b_money = @tax_year.respond_to?(:irmaa_part_b_surcharge) ? @tax_year.irmaa_part_b_surcharge(magi) : Money.new(0)

      economic_gross = base_income[:gross_income] + actual + withdrawals[:added_ordinary_taxable] + withdrawals[:capital_gains_taxable]
      effective_rate = total_tax_money.to_f / [economic_gross.to_f, 1].max

      incremental_tax, incremental_rate = calculate_conversion_tax_impact(
        base_income: base_income,
        taxable_after_conv: taxable_after_conv,
        withdrawals: withdrawals,
        total_tax: total_tax_money,
        actual_conversion: actual
      )

      StrategyResult.new(
        strategy_name: strategy.name,
        year: @tax_year.year,
        base_taxable_income: baseline_taxable.to_f,
        roth_conversion_requested: requested.to_f,
        actual_roth_conversion: actual.to_f,
        taxable_income_after_conversion: taxable_after_conv.to_f,
        magi: magi.to_f,
        after_tax_cash_before_spending_withdrawals: after_tax_cash.to_f,
        remaining_spending_need: remaining_need,
        withdrawals: withdrawals.transform_values(&:to_f),
        federal_tax: federal_tax_money.to_f,
        capital_gains_tax: cap_gains_tax_money.to_f,
        state_tax: state_tax_money.to_f,
        irmaa_part_b: irmaa_part_b_money.to_f,
        effective_tax_rate: effective_rate,
        ss_taxable_post: ss_taxable_post.to_f,
        ss_taxable_increase: ss_taxable_increase.to_f,
        conversion_incremental_tax: incremental_tax.to_f,
        conversion_incremental_marginal_rate: incremental_rate,
        narration: "..."
      )
    end

    def calculate_conversion_tax_impact(base_income:, withdrawals:, total_tax:, actual_conversion:)
      base_total_taxable_ordinary = base_income[:taxable_income] + withdrawals[:added_ordinary_taxable]
      base_ordinary_after_std = [base_total_taxable_ordinary.amount - @tax_year.standard_deduction.amount, 0].max
      base_fed_tax = @tax_year.tax_on_ordinary(Money.new(base_ordinary_after_std))
      base_cap_tax = @tax_year.tax_on_ltcg(withdrawals[:capital_gains_taxable], ordinary_taxable_income: Money.new(base_ordinary_after_std))
      base_total_tax = base_fed_tax + base_cap_tax
      incremental_tax = total_tax - base_total_tax
      incremental_rate = actual_conversion.amount.positive? ? (incremental_tax.to_f / actual_conversion.to_f) : 0.0
      [incremental_tax, incremental_rate]
    end

    def snapshot_accounts
      @household.accounts.map { |acct| [acct, acct.instance_variable_get(:@balance)] }
    end

    def restore_accounts(snapshot)
      snapshot.each do |acct, balance|
        acct.instance_variable_set(:@balance, balance)
      end
    end

    def allocate_spending_gap(need, taxable_after_conv)
      return { cash_from_withdrawals: Money.new(0), added_ordinary_taxable: Money.new(0), capital_gains_taxable: Money.new(0), detail: [] } if need <= 0

      cash = Money.new(0)
      added_ordinary = Money.new(0)
      capital_gains_taxable = Money.new(0)
      detail = []

      @household.taxable_brokerage_accounts.each do |acct|
        break if cash.amount >= need
        to_pull = [need - cash.amount, acct.balance].min
        next if to_pull <= 0
        result = acct.withdraw(to_pull)
        cash += result[:cash]
        capital_gains_taxable += result[:taxable_capital_gains]
        detail << { source: :taxable_brokerage, amount: result[:cash] }
      end

      desired_ceiling = @household.desired_tax_bracket_ceiling
      @household.traditional_iras.each do |acct|
        break if cash.amount >= need
        current_taxable = taxable_after_conv + added_ordinary
        remaining_headroom = desired_ceiling - current_taxable.amount
        break if remaining_headroom <= 0
        to_pull = [need - cash.amount, acct.balance, remaining_headroom].min
        next if to_pull <= 0
        result = acct.withdraw(to_pull)
        cash += result[:cash]
        added_ordinary += result[:taxable_ordinary]
        detail << { source: :traditional_ira, amount: result[:cash] }
      end

      @household.roth_iras.each do |acct|
        break if cash.amount >= need
        to_pull = [need - cash.amount, acct.balance].min
        next if to_pull <= 0
        result = acct.withdraw(to_pull)
        cash += result[:cash]
        detail << { source: :roth_ira, amount: result[:cash] }
      end

      { cash_from_withdrawals: cash, added_ordinary_taxable: added_ordinary, capital_gains_taxable: capital_gains_taxable, detail: detail }
    end
  end
end
