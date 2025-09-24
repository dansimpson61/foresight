import { Controller } from '../vendor/stimulus.js';
import { Chart, registerables } from 'https://cdn.jsdelivr.net/npm/chart.js@4.4.3/+esm';
import { NetWorthChart } from '../charts/NetWorthChart.js';
import { IncomeTaxChart } from '../charts/IncomeTaxChart.js';

Chart.register(...registerables);

export default class extends Controller {
  static targets = ["netWorthCanvas", "incomeTaxCanvas", "irmaaTimeline", "taxEfficiencyGauge"];

  connect() {
    document.addEventListener('plan:results', this.render.bind(this));
  }

  render(event) {
    const results = event.detail?.results;
    if (!results) return;

    const chartsData = results.charts;
    if (chartsData && chartsData.net_worth) {
      new NetWorthChart(this.netWorthCanvasTarget, chartsData.net_worth).render();
    }
    if (chartsData && chartsData.income_tax) {
      new IncomeTaxChart(this.incomeTaxCanvasTarget, chartsData.income_tax).render();
    }

    this.renderIrmaaTimeline(results.yearly);
    this.renderTaxEfficiencyGauge(results.aggregate);
  }

  renderIrmaaTimeline(yearlyData) {
    if (!Array.isArray(yearlyData) || yearlyData.length === 0) return;
    
    const labels = yearlyData.map(r => r.year);
    const irmaaTiers = yearlyData.map(r => r.irmaa_part_b);

    const tierColors = {
        0: '#A5D6A7', // Green
        1: '#FFF176', // Yellow
        2: '#FFB74D', // Orange
        3: '#E57373'  // Red
    };
    const backgroundColors = irmaaTiers.map(tier => tierColors[tier] || '#E0E0E0');

    if (this.irmaaTimelineChart) {
        this.irmaaTimelineChart.destroy();
    }

    this.irmaaTimelineChart = new Chart(this.irmaaTimelineTarget, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'IRMAA Tier',
                data: irmaaTiers,
                backgroundColor: backgroundColors
            }]
        },
        options: {
            indexAxis: 'y',
            scales: {
                x: {
                    display: false
                },
                y: {
                    ticks: {
                        display: false
                    }
                }
            },
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });
  }

  renderTaxEfficiencyGauge(aggregateData) {
    if (!aggregateData) return;

    const roth = aggregateData.ending_balances.roth;
    const traditional = aggregateData.ending_balances.traditional;

    if (this.taxEfficiencyGaugeChart) {
        this.taxEfficiencyGaugeChart.destroy();
    }

    this.taxEfficiencyGaugeChart = new Chart(this.taxEfficiencyGaugeTarget, {
        type: 'doughnut',
        data: {
            labels: ['Roth (Tax-Free)', 'Traditional (Tax-Deferred)'],
            datasets: [{
                data: [roth, traditional],
                backgroundColor: ['#66BB6A', '#42A5F5']
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    position: 'top',
                },
                title: {
                    display: true,
                    text: 'End of Plan Asset Allocation'
                }
            }
        }
    });
  }
}