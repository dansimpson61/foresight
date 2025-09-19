# frozen_string_literal: true

module Foresight
  class AnnualPlanner
    # ... (StrategyResult struct remains the same) ...
    StrategyResult = Struct.new(:strategy_name, :year, :base_taxable_income, :roth_conversion_requested, :actual_roth_conversion, :taxable_income_after_conversion, :magi, :after_tax_cash_before_spending_withdrawals, :remaining_spending_need, :withdrawals, :federal_tax, :capital_gains_tax, :state_tax, :irmaa_part_b, :effective_tax_rate, :ss_taxable_post, :ss_taxable_increase, :conversion_incremental_tax, :conversion_incremental_marginal_rate, :narration, keyword_init: true)


    attr_reader :household, :tax_year

    def initialize(household:, tax_year:)
      @household = household
      @tax_year = tax_year
    end

    def generate_strategy(strategy)
      base_income = compute_base_income
      execute_for_strategy(strategy, base_income)
    end

    private

    def compute_base_income
      year = @tax_year.year
      gross_income = 0.0
      taxable_income = 0.0

      # Salaries and Pensions (Ordinary Income)
      (@household.salaries + @household.pensions).each do |income|
        # Simplified: assume salary stops at 65
        next if income.is_a?(Salary) && income.recipient.age_in(year) >= 65
        gross_income += income.annual_gross
        taxable_income += income.annual_gross
      end
      
      # RMDs are forced ordinary income
      rmds = @household.traditional_iras.sum { |acct| acct.calculate_rmd(acct.owner.age_in(year)) }
      gross_income += rmds
      taxable_income += rmds

      # Social Security is calculated last as its taxability depends on other income
      ss_total = @household.social_security_benefits.sum { |b| b.annual_benefit_for(year) }
      ss_taxable = taxable_social_security(ss_total, other_income: taxable_income)
      
      gross_income += ss_total
      taxable_income += ss_taxable

      {
        gross_income: gross_income,
        taxable_income: taxable_income,
        ss_total: ss_total,
        ss_taxable_baseline: ss_taxable,
        pre_ss_other_income: taxable_income - ss_taxable,
        rmds: rmds
      }
    end

    def taxable_social_security(ss_total, other_income: 0.0)
      thresholds = @tax_year.social_security_taxability_thresholds(@household.filing_status)
      provisional = other_income + (ss_total * 0.5)
      
      # CORRECTED: Use string keys to access hash loaded from YAML
      if provisional <= thresholds['phase1_start']
        0.0
      elsif provisional <= thresholds['phase2_start']
        (provisional - thresholds['phase1_start']) * 0.5
      else
        base_taxable = (thresholds['phase2_start'] - thresholds['phase1_start']) * 0.5
        excess_taxable = (provisional - thresholds['phase2_start']) * 0.85
        [base_taxable + excess_taxable, ss_total * 0.85].min
      end
    end

    def execute_for_strategy(strategy, base_income)
      requested = strategy.conversion_amount(household: @household, tax_year: @tax_year, base_taxable_income: base_income[:taxable_income])
      actual_conversion = perform_roth_conversion(requested)

      ss_taxable_post = taxable_social_security(base_income[:ss_total], other_income: base_income[:pre_ss_other_income] + actual_conversion)
      taxable_after_conv = base_income[:pre_ss_other_income] + actual_conversion + ss_taxable_post
      
      cash_from_income = base_income[:gross_income]
      taxes_before_withdrawals = calculate_taxes(taxable_ordinary: taxable_after_conv, capital_gains: 0.0)
      net_cash_before_withdrawals = cash_from_income - taxes_before_withdrawals[:total_tax]

      remaining_need = [@household.annual_expenses - net_cash_before_withdrawals, 0.0].max
      withdrawals = allocate_spending_gap(remaining_need)

      final_taxable_ordinary = taxable_after_conv + withdrawals[:added_ordinary_taxable]
      final_taxes = calculate_taxes(taxable_ordinary: final_taxable_ordinary, capital_gains: withdrawals[:capital_gains_taxable])
      
      magi = final_taxable_ordinary + withdrawals[:capital_gains_taxable]
      irmaa_part_b = @tax_year.irmaa_part_b_surcharge(magi: magi, status: @household.filing_status)

      StrategyResult.new(
        strategy_name: strategy.name,
        year: @tax_year.year,
        base_taxable_income: base_income[:taxable_income],
        roth_conversion_requested: requested,
        actual_roth_conversion: actual_conversion,
        taxable_income_after_conversion: taxable_after_conv,
        magi: magi,
        after_tax_cash_before_spending_withdrawals: net_cash_before_withdrawals,
        remaining_spending_need: remaining_need,
        withdrawals: withdrawals,
        federal_tax: final_taxes[:federal_tax],
        capital_gains_tax: final_taxes[:capital_gains_tax],
        state_tax: final_taxes[:state_tax],
        irmaa_part_b: irmaa_part_b,
        effective_tax_rate: (final_taxes[:total_tax] / [base_income[:gross_income] + actual_conversion, 1].max),
        ss_taxable_post: ss_taxable_post,
        ss_taxable_increase: ss_taxable_post - base_income[:ss_taxable_baseline]
      )
    end
    
    def calculate_taxes(taxable_ordinary:, capital_gains:)
        ordinary_after_deduction = [taxable_ordinary - @tax_year.standard_deduction(@household.filing_status), 0.0].max
        taxes = @tax_year.calculate(
            filing_status: @household.filing_status,
            taxable_income: ordinary_after_deduction,
            capital_gains: capital_gains
        )
        total = taxes[:federal_tax] + taxes[:state_tax] + taxes[:capital_gains_tax]
        taxes.merge(total_tax: total)
    end

    def perform_roth_conversion(requested_amount)
      return 0.0 if requested_amount <= 0
      
      remaining = requested_amount
      actual = 0.0
      @household.traditional_iras.each do |acct|
        break if remaining <= 0
        slice = [acct.balance, remaining].min
        res = acct.convert_to_roth(slice)
        remaining -= res[:converted]
        actual += res[:converted]
      end
      actual
    end

    def allocate_spending_gap(need)
      return { cash_from_withdrawals: 0.0, added_ordinary_taxable: 0.0, capital_gains_taxable: 0.0, detail: [] } if need <= 0

      cash_raised = 0.0
      added_ordinary = 0.0
      capital_gains = 0.0
      detail = []

      @household.withdrawal_hierarchy.each do |account_type|
        break if cash_raised >= need
        
        accounts = case account_type
          when :cash then @household.cash_accounts
          when :taxable then @household.taxable_brokerage_accounts
          when :traditional then @household.traditional_iras
          when :roth then @household.roth_iras
          end
        
        accounts.each do |acct|
          break if cash_raised >= need
          
          available_balance = acct.is_a?(Cash) ? [acct.balance - @household.emergency_fund_floor, 0.0].max : acct.balance
          to_pull = [need - cash_raised, available_balance].min
          next if to_pull <= 0
          
          result = acct.withdraw(to_pull)
          cash_raised += result[:cash]
          added_ordinary += result[:taxable_ordinary]
          capital_gains += result[:taxable_capital_gains]
          detail << { source: account_type, amount: result[:cash] }
        end
      end
      { cash_from_withdrawals: cash_raised, added_ordinary_taxable: added_ordinary, capital_gains_taxable: capital_gains, detail: detail }
    end
  end
end
