#!/usr/bin/env ruby
# frozen_string_literal: true

module Foresight
  # Simple heuristic-based phase segmentation for multi-year plan results.
  # Phases (when applicable): pre_social_security, social_security_pre_rmd, rmd_phase, depletion_tail, full_period (fallback)
  class PhaseAnalyzer
    Phase = Struct.new(:name, :start_year, :end_year, :metrics, keyword_init: true)

    def initialize(initial_traditional_total:)
      @initial_traditional_total = initial_traditional_total.to_f
    end

    def analyze(yearly)
      return [single_phase(yearly, 'full_period')] if yearly.empty?

      ss_index = yearly.index { |y| positive?(y[:ss_taxable_post]) || positive?(y[:ss_taxable_increase]) }
      rmd_index = yearly.index { |y| positive?(y[:rmd_taken]) }

      tail_index = yearly.index do |y|
        @initial_traditional_total > 0 && (y[:ending_traditional_balance].to_f / @initial_traditional_total) < 0.10
      end

      phases = []

      if ss_index && ss_index > 0
        phases << build_phase(yearly, 0, ss_index - 1, 'pre_social_security')
      end

      if ss_index
        pre_rmd_end = (rmd_index && rmd_index > ss_index) ? rmd_index - 1 : nil
        if pre_rmd_end && pre_rmd_end >= ss_index
          phases << build_phase(yearly, ss_index, pre_rmd_end, 'social_security_pre_rmd')
        end
      end

      # RMD phase (until tail or end)
      if rmd_index
        rmd_end = (tail_index && tail_index > rmd_index) ? tail_index - 1 : yearly.size - 1
        phases << build_phase(yearly, rmd_index, rmd_end, 'rmd_phase')
      end

      # Tail depletion
      if tail_index && tail_index < yearly.size
        phases << build_phase(yearly, tail_index, yearly.size - 1, 'depletion_tail')
      end

      phases = [single_phase(yearly, 'full_period')] if phases.empty?
      phases
    end

    private

    def positive?(val)
      val.to_f > 0.0
    end

    def single_phase(yearly, name)
      build_phase(yearly, 0, yearly.size - 1, name)
    end

    def build_phase(yearly, start_idx, end_idx, name)
      slice = yearly[start_idx..end_idx]
      metrics = compute_metrics(slice)
      Phase.new(
        name: name,
        start_year: slice.first[:year],
        end_year: slice.last[:year],
        metrics: metrics
      )
    end

    def compute_metrics(slice)
      years = slice.size
      conv_total = sum(slice, :actual_roth_conversion)
      effective_avg = avg(slice, :effective_tax_rate)
      marginal_avg = avg(slice, :conversion_incremental_marginal_rate)
      trad_start = slice.first[:ending_traditional_balance]
      trad_end = slice.last[:ending_traditional_balance]
      trad_delta_pct = trad_start.to_f.zero? ? 0.0 : ((trad_end - trad_start) / trad_start.to_f).round(4)
      rmd_pressure_avg = avg(slice, :future_rmd_pressure)
      rmd_pressure_peak = slice.map { |y| y[:future_rmd_pressure].to_f }.max || 0.0
      {
        years: years,
        cumulative_roth_converted: conv_total.round(2),
        avg_effective_tax_rate: effective_avg.round(4),
        avg_conversion_marginal_rate: marginal_avg.round(4),
        starting_trad_balance: trad_start.round(2),
        ending_trad_balance: trad_end.round(2),
        trad_balance_delta_pct: trad_delta_pct,
        avg_future_rmd_pressure: rmd_pressure_avg.round(4),
        peak_future_rmd_pressure: rmd_pressure_peak.round(4)
      }
    end

    def sum(rows, key)
      rows.sum { |r| r[key].to_f }
    end

    def avg(rows, key)
      return 0.0 if rows.empty?
      sum(rows, key) / rows.size.to_f
    end
  end
end
