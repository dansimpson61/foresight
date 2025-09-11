# frozen_string_literal: true

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
      pension_gross = 0.0
      pension_taxable = 0.0
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

    def taxable_social_security(ss_total, other_income: 0.0)
      # Provisional income thresholds vary by filing status
      if @household.filing_status == 'MFJ'
        base_thresh = 32_000
        addl_thresh = 44_000
      else
        base_thresh = 25_000
        addl_thresh = 34_000
      end
      provisional = other_income + 0.5 * ss_total
      if provisional <= base_thresh
        0.0
      elsif provisional <= addl_thresh
        0.5 * (provisional - base_thresh)
      else
        base = 0.5 * (addl_thresh - base_thresh)
        excess = provisional - addl_thresh
        [0.85 * excess + base, 0.85 * ss_total].min
      end
    end

    def execute_for_strategy(strategy, base_income)
      baseline_taxable = base_income[:taxable_income]
      requested = strategy.conversion_amount(household: @household, tax_year: @tax_year, base_taxable_income: baseline_taxable)
      remaining = requested
      actual = 0.0
      if remaining.positive?
        @household.traditional_iras.each do |acct|
          break if remaining <= 0
          slice = [acct.balance, remaining].min
          res = acct.convert_to_roth(slice)
          remaining -= res[:converted]
          actual += res[:converted]
        end
      end
      ss_taxable_post = taxable_social_security(base_income[:ss_total], other_income: base_income[:pre_ss_other_income] + actual)
      taxable_after_conv = base_income[:pre_ss_other_income] + actual + ss_taxable_post
      ss_taxable_increase = ss_taxable_post - base_income[:ss_taxable_baseline]
      after_tax_cash = base_income[:after_tax_cash]
      remaining_need = [@household.target_spending_after_tax - after_tax_cash, 0].max
      withdrawals = allocate_spending_gap(remaining_need, taxable_after_conv)
      total_taxable_ordinary = taxable_after_conv + withdrawals[:added_ordinary_taxable]
      ordinary_taxable_after_std_ded = [total_taxable_ordinary - @tax_year.standard_deduction, 0].max
      federal_tax = @tax_year.tax_on_ordinary(ordinary_taxable_after_std_ded)
      cap_gains_tax = @tax_year.tax_on_ltcg(withdrawals[:capital_gains_taxable], ordinary_taxable_income: ordinary_taxable_after_std_ded)
  total_tax = federal_tax + cap_gains_tax
  # NY state taxable: ordinary taxable after std deduction (no LTCG preference), with NY std deduction
  ny_std = @tax_year.respond_to?(:ny_standard_deduction) ? @tax_year.ny_standard_deduction(@household.filing_status) : 0.0
  ny_taxable = [total_taxable_ordinary - ny_std, 0].max
  state_tax = @tax_year.respond_to?(:ny_tax_on_income) ? @tax_year.ny_tax_on_income(ny_taxable, filing_status: @household.filing_status) : 0.0
  # MAGI approximation (pre-deduction ordinary components + capital gains). Here: total ordinary taxable before std deduction + capital gains.
  magi = total_taxable_ordinary + withdrawals[:capital_gains_taxable]
  irmaa_part_b = @tax_year.respond_to?(:irmaa_part_b_surcharge) ? @tax_year.irmaa_part_b_surcharge(magi) : 0.0
  # Effective tax rate denominator: economic gross cash inflows this year (base gross + conversion + taxable ordinary add-ons + realized capital gains)
  economic_gross = base_income[:gross_income] + actual + withdrawals[:added_ordinary_taxable] + withdrawals[:capital_gains_taxable]
  effective_rate = total_tax / [economic_gross, 1].max
      base_total_taxable_ordinary = base_income[:taxable_income] + withdrawals[:added_ordinary_taxable]
      base_ordinary_after_std = [base_total_taxable_ordinary - @tax_year.standard_deduction, 0].max
      base_fed_tax = @tax_year.tax_on_ordinary(base_ordinary_after_std)
      base_cap_tax = @tax_year.tax_on_ltcg(withdrawals[:capital_gains_taxable], ordinary_taxable_income: base_ordinary_after_std)
      base_total_tax = base_fed_tax + base_cap_tax
  incremental_tax = (total_tax - base_total_tax).round(2)
      incremental_rate = actual.positive? ? (incremental_tax / actual).round(4) : 0.0
      StrategyResult.new(
        strategy_name: strategy.name,
        year: @tax_year.year,
        base_taxable_income: baseline_taxable,
        roth_conversion_requested: requested,
        actual_roth_conversion: actual.round(2),
  taxable_income_after_conversion: taxable_after_conv,
  magi: magi.round(2),
        after_tax_cash_before_spending_withdrawals: after_tax_cash,
        remaining_spending_need: remaining_need,
        withdrawals: withdrawals,
        federal_tax: federal_tax.round(2),
        capital_gains_tax: cap_gains_tax.round(2),
  state_tax: state_tax.round(2),
  irmaa_part_b: irmaa_part_b,
        effective_tax_rate: effective_rate.round(4),
        ss_taxable_post: ss_taxable_post.round(2),
        ss_taxable_increase: ss_taxable_increase.round(2),
        conversion_incremental_tax: incremental_tax,
        conversion_incremental_marginal_rate: incremental_rate,
  narration: build_narration(base: base_income, requested_roth_conv: requested, actual_conversion: actual, remaining_need: remaining_need, withdrawals: withdrawals, total_tax: total_tax, state_tax: state_tax, irmaa_part_b: irmaa_part_b, effective_rate: effective_rate, ss_taxable_post: ss_taxable_post, ss_taxable_increase: ss_taxable_increase, conversion_incremental_marginal_rate: incremental_rate)
      )
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
      return { cash_from_withdrawals: 0.0, added_ordinary_taxable: 0.0, capital_gains_taxable: 0.0, detail: [] } if need <= 0

      cash = 0.0
      added_ordinary = 0.0
      capital_gains_taxable = 0.0
      detail = []

      # 1. Taxable brokerage
      @household.taxable_brokerage_accounts.each do |acct|
        break if cash >= need
        to_pull = [need - cash, acct.balance].min
        next if to_pull <= 0
        result = acct.withdraw(to_pull)
        cash += result[:cash]
        capital_gains_taxable += result[:taxable_capital_gains]
        detail << { source: :taxable_brokerage, amount: result[:cash] }
      end

      # 2. Traditional IRA (respect ceiling)
      desired_ceiling = @household.desired_tax_bracket_ceiling
      @household.traditional_iras.each do |acct|
        break if cash >= need
        current_taxable = taxable_after_conv + added_ordinary
        remaining_headroom = desired_ceiling - current_taxable
        break if remaining_headroom <= 0
        to_pull = [need - cash, acct.balance, remaining_headroom].min
        next if to_pull <= 0
        result = acct.withdraw(to_pull)
        cash += result[:cash]
        added_ordinary += result[:taxable_ordinary]
        detail << { source: :traditional_ira, amount: result[:cash] }
      end

      # 3. Roth IRA last
      @household.roth_iras.each do |acct|
        break if cash >= need
        to_pull = [need - cash, acct.balance].min
        next if to_pull <= 0
        result = acct.withdraw(to_pull)
        cash += result[:cash]
        detail << { source: :roth_ira, amount: result[:cash] }
      end

      { cash_from_withdrawals: cash, added_ordinary_taxable: added_ordinary, capital_gains_taxable: capital_gains_taxable, detail: detail }
    end

    def build_narration(base:, requested_roth_conv:, actual_conversion:, remaining_need:, withdrawals:, total_tax:, state_tax:, irmaa_part_b:, effective_rate:, ss_taxable_post:, ss_taxable_increase:, conversion_incremental_marginal_rate:)
      [
        sentence_base_income(base),
        sentence_conversion(requested_roth_conv, actual_conversion, ss_taxable_increase, ss_taxable_post, conversion_incremental_marginal_rate),
        sentence_spending_gap(remaining_need, withdrawals),
        sentence_taxes(total_tax, state_tax, irmaa_part_b, effective_rate)
      ].compact.join(' ')
    end

    def sentence_base_income(base)
      "Base taxable income: #{format('%.2f', base[:taxable_income])}."
    end

    def sentence_conversion(requested, actual, ss_increase, ss_post, incr_rate)
      return "No Roth conversion (no bracket headroom)." unless requested.positive?
      parts = []
      if (requested - actual).abs > 0.01
        parts << "Planned conversion #{format('%.2f', requested)}; executed #{format('%.2f', actual)} (limited by balance)."
      else
        parts << "Executed Roth conversion: #{format('%.2f', actual)} to fill bracket headroom."
      end
      parts << "Conversion increased taxable Social Security by #{format('%.2f', ss_increase)} (now #{format('%.2f', ss_post)})." if ss_increase.positive?
      parts << "Approx marginal rate on conversion: #{(incr_rate * 100).round(2)}%."
      parts.join(' ')
    end

    def sentence_spending_gap(remaining_need, withdrawals)
      if remaining_need.positive?
        detail = withdrawals[:detail].map { |d| "#{d[:source]} #{format('%.2f', d[:amount])}" }.join(', ')
        "Remaining after-tax spending gap: #{format('%.2f', remaining_need)} met via withdrawals: #{detail}."
      else
        "All spending covered by base income; no discretionary withdrawals required."
      end
    end

    def sentence_taxes(total_tax, state_tax, irmaa_part_b, effective_rate)
      "Total federal tax (ordinary + CG): #{format('%.2f', total_tax)}; NY state: #{format('%.2f', state_tax)}; IRMAA Part B: #{format('%.2f', irmaa_part_b)}; effective rate #{(effective_rate * 100).round(2)}%."
    end
  end
end
