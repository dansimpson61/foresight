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

/**
 * Prepares the labels and datasets for the income and tax chart.
 * This function isolates the data transformation logic.
 * @param {Array} yearlyData - The raw data array for each year.
 * @returns {Object} An object containing the formatted labels and datasets.
 */
prepareIncomeChartData(yearlyData) {
  const labels = yearlyData.map(r => r.year);
  
  // 1. Define Income Sources (Stacked Area Datasets)
  const incomeSources = [
    { key: 'ss_benefits', label: 'Taxable Social Security', color: 'rgba(117, 117, 117, 0.7)' },
      { key: 'pensions', label: 'Pensions', color: 'rgba(189, 189, 189, 0.7)' },
      { key: 'salaries', label: 'Salary', color: 'rgba(158, 158, 158, 0.7)' },
      { key: 'capital_gains', label: 'Capital Gains', color: 'rgba(97, 97, 97, 0.7)' },
      { key: 'rmds', label: 'RMDs', color: 'rgba(66, 66, 66, 0.7)' },
      { key: 'spending_withdrawals_ordinary', label: 'Taxable Withdrawals', color: 'rgba(186, 104, 200, 0.7)' },
      { key: 'roth_conversions', label: 'Roth Conversion', color: 'rgba(239, 83, 80, 0.7)' },
  ];

  const incomeDatasets = incomeSources.map(source => ({
      label: source.label,
      data: yearlyData.map(r => r.taxable_income_breakdown[source.key] || 0),
      borderColor: 'transparent',
      backgroundColor: source.color,
      pointRadius: 0,
    fill: true,
    stack: 'income', // stack group for income only
    yAxisID: 'y',
    order: 0
  }));

  // 2. Define Reference Lines (Independent Datasets)
  const taxBrackets = yearlyData[0].tax_brackets;
  const stdDeduction = taxBrackets.standard_deduction;

  const stdDeductionLine = {
      label: 'Standard Deduction',
      data: Array(labels.length).fill(stdDeduction),
      borderColor: 'rgba(158, 158, 158, 0.8)',
      borderDash: [2, 3],
      borderWidth: 1.5,
      pointRadius: 0,
    fill: false,
    yAxisID: 'y',
    stack: 'ref_std', // unique stack so it never stacks with income or other refs
    order: 100
  };

  const bracketLines = taxBrackets.brackets.map(bracket => {
    const rateLabel = `${(bracket.rate * 100).toFixed(0)}%`;
    return {
      label: `${rateLabel} Bracket Ceiling`,
      data: Array(labels.length).fill(bracket.ceiling + stdDeduction),
      borderColor: 'rgba(33, 150, 243, 0.5)',
      borderDash: [5, 5],
      borderWidth: 1,
      pointRadius: 0,
      fill: false,
      yAxisID: 'y',
      stack: `ref_${rateLabel}`, // unique stack per bracket
      order: 100
    };
  });
  
  // 3. Define the Secondary Axis Line
  const totalTaxLine = {
      label: 'Total Tax',
      data: yearlyData.map(r => r.all_in_tax),
      borderColor: '#D32F2F',
      borderWidth: 2,
      yAxisID: 'y1', // Assigns to the right-hand axis
      pointRadius: 1,
      fill: false,
    tension: 0.1,
    order: 110
  };

  // 4. Combine all datasets
  const datasets = [...incomeDatasets, stdDeductionLine, ...bracketLines, totalTaxLine];

  return { labels, datasets };
}

/**
* Renders the income and tax chart onto the canvas.
* This function now focuses solely on chart configuration and rendering.
* @param {Array} yearlyData - The raw data array for each year.
*/
renderIncomeAndTaxChart(yearlyData) {
  // Validate the data before proceeding
  if (!Array.isArray(yearlyData) || yearlyData.length === 0 || !yearlyData[0].taxable_income_breakdown || !yearlyData[0].tax_brackets) {
    return;
  }
  
  // Get the prepared data
  const { labels, datasets } = this.prepareIncomeChartData(yearlyData);

  // Destroy the previous chart instance if it exists
  if (this.incomeTaxChart) {
    this.incomeTaxChart.destroy();
  }
  
  // Create the new chart
  this.incomeTaxChart = new Chart(this.incomeTaxCanvasTarget, {
    type: 'line',
    data: { labels, datasets },
    options: {
      plugins: {
        tooltip: { mode: 'index', intersect: false },
        filler: { drawTime: 'beforeDatasetsDraw' } // draw area fills first so lines appear on top
      },
      scales: {
        x: {},
        y: { 
          stacked: true, // stacks only datasets sharing the same `stack` id
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
