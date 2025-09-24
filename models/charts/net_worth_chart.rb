# frozen_string_literal: true

module Foresight
  module Charts
    # Prepares the data for the Net Worth chart in a format
    # directly consumable by Chart.js.
    class NetWorthChart
      def self.prepare(yearly_data)
        return nil unless yearly_data&.any?

        {
          type: 'bar',
          data: {
            labels: yearly_data.map { |r| r[:year] },
            datasets: [
              {
                label: 'Taxable',
                data: yearly_data.map { |r| r[:ending_taxable_balance] },
                backgroundColor: '#B0BEC5'
              },
              {
                label: 'Traditional IRA/401k',
                data: yearly_data.map { |r| r[:ending_traditional_balance] },
                backgroundColor: '#42A5F5'
              },
              {
                label: 'Roth IRA/401k',
                data: yearly_data.map { |r| r[:ending_roth_balance] },
                backgroundColor: '#66BB6A'
              }
            ]
          },
          options: {
            plugins: {
              tooltip: {
                mode: 'index',
                intersect: false
              }
            },
            scales: {
              x: { stacked: true },
              y: { stacked: true }
            }
          }
        }
      end
    end
  end
end