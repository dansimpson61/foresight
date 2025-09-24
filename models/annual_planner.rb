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
      # This is the single entry point. It orchestrates the entire annual calculation.
      execute_for_strategy(strategy)
    end

    private

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

    def execute_for_strategy(strategy)
      year = @tax_year.year
      financial_events = []

      # Step 1: Calculate all non-discretionary income to establish a firm baseline.
      base_breakdown = { salaries: 0.0, pensions: 0.0, rmds: 0.0, ss_benefits: 0.0 }
      base_breakdown[:salaries] = @household.salaries.sum { |s| s.gross_for(year) }
      base_breakdown[:pensions] = @household.pensions.sum { |p| p.gross_for(year) }

      @household.traditional_iras.each do |acct|
        rmd_amount = acct.calculate_rmd(acct.owner.age_in(year))
        if rmd_amount > 0
          financial_events << FinancialEvent::RequiredMinimumDistribution.new(year: year, source_account: acct, amount: rmd_amount)
          base_breakdown[:rmds] += rmd_amount
        end
      end

      ss_total = @household.social_security_benefits.sum { |b| b.annual_benefit_for(year) }
      provisional_income_for_ss = base_breakdown[:salaries] + base_breakdown[:pensions] + base_breakdown[:rmds]
      base_breakdown[:ss_benefits] = taxable_social_security(ss_total, other_income: provisional_income_for_ss)
      
      base_taxable_income = base_breakdown.values.sum
      base_gross_income = base_breakdown[:salaries] + base_breakdown[:pensions] + ss_total + base_breakdown[:rmds]
      
      # Step 2: Determine spending need based on this stable baseline.
      taxes_before_strategy = calculate_taxes(taxable_ordinary: base_taxable_income, capital_gains: 0.0)
      net_cash = base_gross_income - taxes_before_strategy[:total_tax]
      remaining_spending_need = [@household.annual_expenses - net_cash, 0.0].max

      # Step 3: Delegate to the strategy object to get all discretionary events.
      discretionary_events = strategy.plan_discretionary_events(
        household: @household, tax_year: @tax_year,
        base_taxable_income: base_taxable_income, spending_need: remaining_spending_need
      )
      financial_events.concat(discretionary_events)
      
      # Step 4: Create the final income breakdown by adding discretionary income to the baseline.
      final_breakdown = base_breakdown.merge(
        spending_withdrawals_ordinary: 0.0, roth_conversions: 0.0, capital_gains: 0.0
      )
      discretionary_events.each do |event|
        final_breakdown[:spending_withdrawals_ordinary] += event.taxable_ordinary if event.is_a?(FinancialEvent::SpendingWithdrawal)
        final_breakdown[:capital_gains] += event.taxable_capital_gains if event.is_a?(FinancialEvent::SpendingWithdrawal)
        final_breakdown[:roth_conversions] += event.taxable_ordinary if event.is_a?(FinancialEvent::RothConversion)
      end
      
      # Step 5: Finalize Social Security taxability and total taxes for the year.
      final_provisional_income = final_breakdown.except(:ss_benefits, :capital_gains).values.sum
      final_breakdown[:ss_benefits] = taxable_social_security(ss_total, other_income: final_provisional_income)

      total_ordinary = final_breakdown.except(:capital_gains).values.sum
      final_taxes = calculate_taxes(taxable_ordinary: total_ordinary, capital_gains: final_breakdown[:capital_gains])
      
      magi = total_ordinary + final_breakdown[:capital_gains]
      irmaa_part_b = @tax_year.irmaa_part_b_surcharge(magi: magi, status: @household.filing_status)

      StrategyResult.new(
        strategy_name: strategy.name, year: @tax_year.year,
        taxable_income_breakdown: final_breakdown.transform_values(&:round),
        tax_brackets: @tax_year.brackets_for_status(@household.filing_status),
        financial_events: financial_events, magi: magi,
        after_tax_cash_before_spending_withdrawals: net_cash,
        remaining_spending_need: remaining_spending_need,
        withdrawals: { cash_from_withdrawals: discretionary_events.select { |e| e.is_a?(FinancialEvent::SpendingWithdrawal)}.sum(&:amount_withdrawn) },
        federal_tax: final_taxes[:federal_tax], capital_gains_tax: final_taxes[:capital_gains_tax],
        state_tax: final_taxes[:state_tax], irmaa_part_b: irmaa_part_b,
        effective_tax_rate: (final_taxes[:total_tax] / [base_gross_income, 1].max),
        ss_taxable_baseline: base_breakdown[:ss_benefits],
        ss_taxable_post: final_breakdown[:ss_benefits],
        ss_taxable_increase: final_breakdown[:ss_benefits] - base_breakdown[:ss_benefits]
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
