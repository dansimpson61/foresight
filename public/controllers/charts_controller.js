import { Controller } from '../vendor/stimulus.js';
import { Chart, registerables } from 'https://cdn.jsdelivr.net/npm/chart.js@4.4.3/+esm';
Chart.register(...registerables);

export default class extends Controller {
  static targets = ["netWorthCanvas", "incomeTaxCanvas", "irmaaTimeline", "taxEfficiencyGauge"];

  connect() {
    document.addEventListener('plan:results', this.render.bind(this));
  }

  render(event) {
    const results = event.detail?.results;
    if (!results) return;

    this.renderNetWorthChart(results.yearly);
    this.renderIncomeAndTaxChart(results.yearly);
    this.renderIrmaaTimeline(results.yearly);
    this.renderTaxEfficiencyGauge(results.aggregate);
  }

  renderNetWorthChart(yearlyData) {
    if (!Array.isArray(yearlyData) || yearlyData.length === 0) return;

    const labels = yearlyData.map(r => r.year);
    const taxableData = yearlyData.map(r => r.ending_taxable_balance);
    const traditionalData = yearlyData.map(r => r.ending_traditional_balance);
    const rothData = yearlyData.map(r => r.ending_roth_balance);

    if (this.netWorthChart) {
      this.netWorthChart.destroy();
    }

    this.netWorthChart = new Chart(this.netWorthCanvasTarget, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Taxable',
            data: taxableData,
            backgroundColor: '#B0BEC5',
          },
          {
            label: 'Traditional IRA/401k',
            data: traditionalData,
            backgroundColor: '#42A5F5',
          },
          {
            label: 'Roth IRA/401k',
            data: rothData,
            backgroundColor: '#66BB6A',
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
          }
        }
      }
    });
  }

  renderIncomeAndTaxChart(yearlyData) {
    if (!Array.isArray(yearlyData) || yearlyData.length === 0) return;

    const labels = yearlyData.map(r => r.year);
    const taxableSS = yearlyData.map(r => r.taxable_social_security);
    const pensions = yearlyData.map(r => r.pension_income);
    const salary = yearlyData.map(r => r.salary);
    const capitalGains = yearlyData.map(r => r.capital_gains_realized);
    const rmds = yearlyData.map(r => r.rmd);
    const rothConversions = yearlyData.map(r => r.requested_roth_conversion);
    const totalTax = yearlyData.map(r => r.all_in_tax);

    if (this.incomeTaxChart) {
      this.incomeTaxChart.destroy();
    }

    this.incomeTaxChart = new Chart(this.incomeTaxCanvasTarget, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [
                { label: 'Taxable Social Security', data: taxableSS, backgroundColor: '#CFD8DC' },
                { label: 'Pensions', data: pensions, backgroundColor: '#90A4AE' },
                { label: 'Salary', data: salary, backgroundColor: '#607D8B' },
                { label: 'Capital Gains', data: capitalGains, backgroundColor: '#546E7A' },
                { label: 'RMDs', data: rmds, backgroundColor: '#455A64' },
                { label: 'Roth Conversion', data: rothConversions, backgroundColor: '#37474F' },
                {
                    label: 'Total Tax',
                    data: totalTax,
                    type: 'line',
                    borderColor: '#EF5350',
                    yAxisID: 'y1'
                }
            ]
        },
        options: {
            plugins: {
                tooltip: { mode: 'index', intersect: false },
            },
            scales: {
                x: { stacked: true },
                y: { stacked: true },
                y1: {
                    type: 'linear',
                    display: true,
                    position: 'right',
                    grid: { drawOnChartArea: false }
                }
            }
        }
    });
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
    const total = roth + traditional;

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
