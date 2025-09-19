#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

module Foresight
  class LifePlanner
    # ... (Structs) ...
    def simulate_on(household, strategy)
      summaries = []
      @years.times do |i|
        current_year = @start_year + i
        puts "\n--- LifePlanner: Simulating Year #{current_year} for #{strategy.key} ---"
        puts "Household Pre-Annual Plan: Trad=#{household.traditional_iras.sum(&:balance)}, Roth=#{household.roth_iras.sum(&:balance)}"
        
        annual_planner = AnnualPlanner.new(household: household, tax_year: TaxYear.new(year: current_year))
        result = annual_planner.generate_strategy(strategy)
        
        household.grow_assets(growth_assumptions: @growth_assumptions, inflation_rate: @inflation_rate)
        
        puts "Household Post-Growth: Trad=#{household.traditional_iras.sum(&:balance)}, Roth=#{household.roth_iras.sum(&:balance)}"
        summaries << build_summary(household, result, current_year, strategy)
      end
      summaries
    end
    # ... (rest of class) ...
  end
end
