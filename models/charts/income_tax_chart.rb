# frozen_string_literal: true

module Foresight
  module Charts
    # Prepares the data for the Income & Tax chart in a format
    # directly consumable by Chart.js.
    class IncomeTaxChart
      def self.prepare(yearly_data)
        return nil unless yearly_data&.any? && yearly_data.first[:taxable_income_breakdown] && yearly_data.first[:tax_brackets]

        labels = yearly_data.map { |r| r[:year] }
        datasets = build_datasets(yearly_data)

        {
          type: 'line',
          data: { labels: labels, datasets: datasets },
          options: {
            plugins: {
              tooltip: { mode: 'index', intersect: false },
              filler: { drawTime: 'beforeDatasetsDraw' }
            },
            scales: {
              x: {},
              y: {
                stacked: true,
                title: { display: true, text: 'Total Income' }
              },
              y1: {
                type: 'linear',
                display: true,
                position: 'right',
                grid: { drawOnChartArea: false },
                title: { display: true, text: 'Annual Tax' }
              }
            },
            interaction: { mode: 'index', intersect: false }
          }
        }
      end

      def self.build_datasets(yearly_data)
        income_datasets = build_income_datasets(yearly_data)
        ref_lines = build_reference_lines(yearly_data)
        tax_line = build_tax_line(yearly_data)

        income_datasets + ref_lines + [tax_line]
      end

      def self.build_income_datasets(yearly_data)
        sources = [
          { key: 'ss_benefits', label: 'Taxable Social Security', color: 'rgba(117, 117, 117, 0.7)' },
          { key: 'pensions', label: 'Pensions', color: 'rgba(189, 189, 189, 0.7)' },
          { key: 'salaries', label: 'Salary', color: 'rgba(158, 158, 158, 0.7)' },
          { key: 'capital_gains', label: 'Capital Gains', color: 'rgba(97, 97, 97, 0.7)' },
          { key: 'rmds', label: 'RMDs', color: 'rgba(66, 66, 66, 0.7)' },
          { key: 'spending_withdrawals_ordinary', label: 'Taxable Withdrawals', color: 'rgba(186, 104, 200, 0.7)' },
          { key: 'roth_conversions', label: 'Roth Conversion', color: 'rgba(239, 83, 80, 0.7)' }
        ]

        sources.map do |source|
          {
            label: source[:label],
            data: yearly_data.map { |r| r[:taxable_income_breakdown][source[:key]] || 0 },
            borderColor: 'transparent',
            backgroundColor: source[:color],
            pointRadius: 0,
            fill: true,
            stack: 'income',
            yAxisID: 'y',
            order: 0
          }
        end
      end

      def self.build_reference_lines(yearly_data)
        tax_brackets = yearly_data.first[:tax_brackets]
        std_deduction = tax_brackets[:standard_deduction]
        labels_count = yearly_data.size

        deduction_line = {
          label: 'Standard Deduction',
          data: Array.new(labels_count, std_deduction),
          borderColor: 'rgba(158, 158, 158, 0.8)',
          borderDash: [2, 3],
          borderWidth: 1.5,
          pointRadius: 0,
          fill: false,
          yAxisID: 'y',
          stack: 'ref_std',
          order: 100
        }

        bracket_lines = tax_brackets[:brackets].map do |bracket|
          {
            label: "#{(bracket['rate'] * 100).to_i}% Bracket Ceiling",
            data: Array.new(labels_count, bracket['ceiling'] + std_deduction),
            borderColor: 'rgba(33, 150, 243, 0.5)',
            borderDash: [5, 5],
            borderWidth: 1,
            pointRadius: 0,
            fill: false,
            yAxisID: 'y',
            stack: "ref_#{(bracket['rate'] * 100).to_i}",
            order: 100
          }
        end

        [deduction_line] + bracket_lines
      end

      def self.build_tax_line(yearly_data)
        {
          label: 'Total Tax',
          data: yearly_data.map { |r| r[:all_in_tax] },
          borderColor: '#D32F2F',
          borderWidth: 2,
          yAxisID: 'y1',
          pointRadius: 1,
          fill: false,
          tension: 0.1,
          order: 110
        }
      end

      private_class_method :build_datasets, :build_income_datasets, :build_reference_lines, :build_tax_line
    end
  end
end