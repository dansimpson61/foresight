# frozen_string_literal: true
require_relative 'financial_event'

module Foresight
  class AnnualPlanner
    StrategyResult = Struct.new(:strategy_name, :year, :taxable_income_breakdown, :tax_brackets, :financial_events, :magi, :after_tax_cash_before_spending_withdrawals, :remaining_spending_need, :withdrawals, :federal_tax, :capital_gains_tax, :state_tax, :irmaa_part_b, :effective_tax_rate, :ss_taxable_baseline, :ss_taxable_post, :ss_taxable_increase, :narration, keyword_init: true)

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
      breakdown = {
        salaries: @household.salaries.sum { |s| s.gross_for(year) },
        pensions: @household.pensions.sum(&:annual_gross),
        ss_benefits: 0.0, rmds: 0.0,
        spending_withdrawals_ordinary: 0.0, roth_conversions: 0.0, capital_gains: 0.0,
      }
      ss_total = @household.social_security_benefits.sum { |b| b.annual_benefit_for(year) }
      pre_ss_other_income = breakdown[:salaries] + breakdown[:pensions]
      ss_taxable_baseline = taxable_social_security(ss_total, other_income: pre_ss_other_income)
      breakdown[:ss_benefits] = ss_taxable_baseline
      { breakdown: breakdown, ss_total: ss_total, ss_taxable_baseline: ss_taxable_baseline }
    end

    def taxable_social_security(ss_total, other_income: 0.0)
      thresholds = @tax_year.social_security_taxability_thresholds(@household.filing_status)
      provisional = other_income + (ss_total * 0.5);
      return 0.0 if provisional <= thresholds['phase1_start']
      if provisional <= thresholds['phase2_start']
        (provisional - thresholds['phase1_start']) * 0.5
      else
        base = (thresholds['phase2_start'] - thresholds['phase1_start']) * 0.5
        excess = (provisional - thresholds['phase2_start']) * 0.85
        [base + excess, ss_total * 0.85].min
      end
    end

    def execute_for_strategy(strategy, base_income)
      financial_events = []; breakdown = base_income[:breakdown].dup

      # RMDs are non-discretionary and calculated first.
      @household.traditional_iras.each do |acct|
        rmd = acct.calculate_rmd(acct.owner.age_in(@tax_year.year))
        if rmd > 0
          event = FinancialEvent::RequiredMinimumDistribution.new(year: @tax_year.year, source_account: acct, amount: rmd)
          financial_events << event; breakdown[:rmds] += event.taxable_ordinary
        end
      end
      
      # Determine spending need before the strategy is applied.
      base_gross = breakdown.values_at(:salaries, :pensions).sum + base_income[:ss_total] + breakdown[:rmds]
      base_taxable = breakdown.values_at(:salaries, :pensions, :rmds).sum
      taxes_before_strategy = calculate_taxes(taxable_ordinary: base_taxable, capital_gains: 0.0)
      net_cash = base_gross - taxes_before_strategy[:total_tax]
      remaining_need = [@household.annual_expenses - net_cash, 0.0].max
      
      # DELEGATE to the strategy object to get all discretionary events.
      discretionary_events = strategy.plan_discretionary_events(
        household: @household, tax_year: @tax_year,
        base_taxable_income: base_taxable, spending_need: remaining_need
      )
      financial_events.concat(discretionary_events)
      
      # Update the income breakdown based on the events returned by the strategy.
      discretionary_events.each do |event|
        breakdown[:spending_withdrawals_ordinary] += event.taxable_ordinary if event.is_a?(FinancialEvent::SpendingWithdrawal)
        breakdown[:capital_gains] += event.taxable_capital_gains if event.is_a?(FinancialEvent::SpendingWithdrawal)
        breakdown[:roth_conversions] += event.taxable_ordinary if event.is_a?(FinancialEvent::RothConversion)
      end

      # Finalize Social Security taxability and total taxes for the year.
      final_income_before_ss = breakdown.values_at(:salaries, :pensions, :rmds, :roth_conversions, :spending_withdrawals_ordinary).sum
      ss_taxable_post = taxable_social_security(base_income[:ss_total], other_income: final_income_before_ss)
      breakdown[:ss_benefits] = ss_taxable_post
      
      total_ordinary = breakdown.except(:capital_gains).values.sum
      final_taxes = calculate_taxes(taxable_ordinary: total_ordinary, capital_gains: breakdown[:capital_gains])
      
      magi = total_ordinary + breakdown[:capital_gains]
      irmaa_part_b = @tax_year.irmaa_part_b_surcharge(magi: magi, status: @household.filing_status)

      StrategyResult.new(
        strategy_name: strategy.name, year: @tax_year.year,
        taxable_income_breakdown: breakdown.transform_values(&:round),
        tax_brackets: @tax_year.brackets_for_status(@household.filing_status),
        financial_events: financial_events, magi: magi,
        after_tax_cash_before_spending_withdrawals: net_cash,
        remaining_spending_need: remaining_need,
        withdrawals: { cash_from_withdrawals: discretionary_events.select { |e| e.is_a?(FinancialEvent::SpendingWithdrawal)}.sum(&:amount_withdrawn) },
        federal_tax: final_taxes[:federal_tax], capital_gains_tax: final_taxes[:capital_gains_tax],
        state_tax: final_taxes[:state_tax], irmaa_part_b: irmaa_part_b,
        effective_tax_rate: (final_taxes[:total_tax] / [base_gross, 1].max),
        ss_taxable_baseline: base_income[:ss_taxable_baseline], ss_taxable_post: ss_taxable_post,
        ss_taxable_increase: ss_taxable_post - ss_taxable_post
      )
    end
    
    def calculate_taxes(taxable_ordinary:, capital_gains:)
      deduction = @tax_year.standard_deduction(@household.filing_status)
      ordinary_after_deduction = [taxable_ordinary - deduction, 0.0].max
      taxes = @tax_year.calculate(filing_status: @household.filing_status, taxable_income: ordinary_after_deduction, capital_gains: capital_gains)
      total = taxes[:federal_tax] + taxes[:state_tax] + taxes[:capital_gains_tax]
      taxes.merge(total_tax: total)
    end
  end
end
