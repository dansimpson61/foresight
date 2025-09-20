# frozen_string_literal: true
require_relative 'financial_event'

module Foresight
  class AnnualPlanner
    StrategyResult = Struct.new(:strategy_name, :year, :base_taxable_income, :financial_events, :magi, :after_tax_cash_before_spending_withdrawals, :remaining_spending_need, :withdrawals, :federal_tax, :capital_gains_tax, :state_tax, :irmaa_part_b, :effective_tax_rate, :ss_taxable_baseline, :ss_taxable_post, :ss_taxable_increase, :narration, keyword_init: true)


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
        next if income.is_a?(Salary) && income.recipient.age_in(year) >= 65
        gross_income += income.annual_gross
        taxable_income += income.annual_gross
      end
      
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
        pre_ss_other_income: taxable_income - ss_taxable
      }
    end

    def taxable_social_security(ss_total, other_income: 0.0)
      thresholds = @tax_year.social_security_taxability_thresholds(@household.filing_status)
      provisional = other_income + (ss_total * 0.5)
      
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
      financial_events = []
      
      @household.traditional_iras.each do |acct|
          rmd_amount = acct.calculate_rmd(acct.owner.age_in(@tax_year.year))
          if rmd_amount > 0
              financial_events << FinancialEvent::RequiredMinimumDistribution.new(
                year: @tax_year.year,
                source_account: acct,
                amount: rmd_amount
              )
          end
      end
      rmd_taxable_income = financial_events.sum(&:taxable_ordinary)
      
      income_for_strategy = base_income[:pre_ss_other_income] + rmd_taxable_income
      
      requested_conversion = strategy.conversion_amount(
        household: @household, 
        tax_year: @tax_year, 
        base_taxable_income: income_for_strategy
      )
      conversion_events = perform_roth_conversion(requested_conversion)
      financial_events.concat(conversion_events)
      
      conversion_taxable_income = conversion_events.sum(&:taxable_ordinary)
      
      income_before_ss_recalc = base_income[:pre_ss_other_income] + rmd_taxable_income + conversion_taxable_income
      ss_taxable_post = taxable_social_security(base_income[:ss_total], other_income: income_before_ss_recalc)
      taxable_after_conv = income_before_ss_recalc + ss_taxable_post
      
      cash_from_income = base_income[:gross_income] + rmd_taxable_income
      taxes_before_withdrawals = calculate_taxes(taxable_ordinary: taxable_after_conv, capital_gains: 0.0)
      net_cash_before_withdrawals = cash_from_income - taxes_before_withdrawals[:total_tax]

      remaining_need = [@household.annual_expenses - net_cash_before_withdrawals, 0.0].max
      spending_events = allocate_spending_gap(remaining_need)
      financial_events.concat(spending_events)
      
      total_ordinary_taxable = financial_events.sum(&:taxable_ordinary) + base_income[:pre_ss_other_income] + ss_taxable_post
      total_cg_taxable = spending_events.sum(&:taxable_capital_gains)
      final_taxes = calculate_taxes(taxable_ordinary: total_ordinary_taxable, capital_gains: total_cg_taxable)
      
      magi = total_ordinary_taxable + total_cg_taxable
      irmaa_part_b = @tax_year.irmaa_part_b_surcharge(magi: magi, status: @household.filing_status)

      StrategyResult.new(
        strategy_name: strategy.name,
        year: @tax_year.year,
        base_taxable_income: base_income[:taxable_income],
        financial_events: financial_events,
        magi: magi,
        after_tax_cash_before_spending_withdrawals: net_cash_before_withdrawals,
        remaining_spending_need: remaining_need,
        withdrawals: { 
          cash_from_withdrawals: spending_events.sum(&:amount_withdrawn),
          added_ordinary_taxable: spending_events.sum(&:taxable_ordinary),
          capital_gains_taxable: spending_events.sum(&:taxable_capital_gains)
        },
        federal_tax: final_taxes[:federal_tax],
        capital_gains_tax: final_taxes[:capital_gains_tax],
        state_tax: final_taxes[:state_tax],
        irmaa_part_b: irmaa_part_b,
        effective_tax_rate: (final_taxes[:total_tax] / [base_income[:gross_income] + conversion_taxable_income + rmd_taxable_income, 1].max),
        ss_taxable_baseline: base_income[:ss_taxable_baseline],
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
      return [] if requested_amount <= 0
      
      events = []
      remaining_to_convert = requested_amount
      
      @household.traditional_iras.each do |acct|
        break if remaining_to_convert <= 0
        conversion_amount = [acct.balance, remaining_to_convert].min
        destination_acct = @household.roth_iras.find { |r| r.owner == acct.owner }
        next unless destination_acct

        result = acct.convert_to_roth(conversion_amount)
        if result[:converted] > 0
          events << FinancialEvent::RothConversion.new(
            year: @tax_year.year, source_account: acct,
            destination_account: destination_acct, amount: result[:converted]
          )
          remaining_to_convert -= result[:converted]
        end
      end
      events
    end

    def allocate_spending_gap(need)
      return [] if need <= 0
      events = []
      cash_raised = 0.0

      @household.withdrawal_hierarchy.each do |account_type|
        break if cash_raised >= need
        
        accounts_of_type = case account_type
          when :cash then @household.cash_accounts
          when :taxable then @household.taxable_brokerage_accounts
          when :traditional then @household.traditional_iras
          when :roth then @household.roth_iras
          end
        
        accounts_of_type.each do |acct|
          break if cash_raised >= need
          
          available_balance = acct.is_a?(Foresight::Cash) ? [acct.balance - @household.emergency_fund_floor, 0.0].max : acct.balance
          amount_to_pull = [need - cash_raised, available_balance].min
          next if amount_to_pull <= 0
          
          result = acct.withdraw(amount_to_pull)
          
          if result[:cash] > 0
            events << FinancialEvent::SpendingWithdrawal.new(
              year: @tax_year.year, source_account: acct,
              amount_withdrawn: result[:cash], taxable_ordinary: result[:taxable_ordinary],
              taxable_capital_gains: result[:taxable_capital_gains]
            )
            cash_raised += result[:cash]
          end
        end
      end
      events
    end
  end
end
