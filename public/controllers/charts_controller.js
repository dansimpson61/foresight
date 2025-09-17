import { Controller } from '../vendor/stimulus.js';
import { Chart, registerables } from 'https://cdn.jsdelivr.net/npm/chart.js@4.4.3/+esm';
Chart.register(...registerables);

export default class extends Controller {
  static targets = ["canvas"];

  connect() {
    document.addEventListener('plan:results', this.render.bind(this));
  }

  render(event) {
    const results = event.detail?.results?.yearly;
    if (!Array.isArray(results) || results.length === 0) {
      return;
    }

    const labels = results.map(r => r.year);
    const taxableData = results.map(r => r.ending_taxable_balance);
    const traditionalData = results.map(r => r.ending_traditional_balance);
    const rothData = results.map(r => r.ending_roth_balance);
    const taxData = results.map(r => r.federal_tax);
    const netWorthData = results.map(r => r.ending_net_worth);


    if (this.chart) {
      this.chart.destroy();
    }

    this.chart = new Chart(this.canvasTarget, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Taxable',
            data: taxableData,
            fill: true,
            backgroundColor: '#B0BEC5',
            borderColor: '#B0BEC5',
            tension: 0.1,
          },
          {
            label: 'Traditional IRA/401k',
            data: traditionalData,
            fill: true,
            backgroundColor: '#42A5F5',
            borderColor: '#42A5F5',
            tension: 0.1,
          },
          {
            label: 'Roth IRA/401k',
            data: rothData,
            fill: true,
            backgroundColor: '#66BB6A',
            borderColor: '#66BB6A',
            tension: 0.1,
          },
          {
            label: 'Annual Tax Liability',
            data: taxData,
            type: 'line',
            borderColor: '#EF5350',
            tension: 0.1,
            yAxisID: 'y1',
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
          x: {
            stacked: true,
          },
          y: {
            stacked: true
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            grid: {
              drawOnChartArea: false,
            }
          }
        }
      }
    });
  }
}
