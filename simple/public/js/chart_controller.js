// A Stimulus controller using Chart.js for clear, maintainable visualization
class ChartController extends Stimulus.Controller {
  static targets = ["table", "canvas", "legend"]

  connect() {
    const chartJSON = JSON.parse(document.getElementById('simulation-data').textContent);
    this.chartData = chartJSON.fill_bracket;
    this.tableTarget.classList.add('hidden');

    this.chartConfig = [
      { key: 'social_security', label: 'Social Security', color: '#a3e635', source: 'income_sources' },
      { key: 'rmd',             label: 'RMDs',            color: '#6b7280', source: 'income_sources' },
      { key: 'withdrawals',     label: 'Withdrawals',     color: '#f97316', source: 'income_sources' },
      { key: 'conversions',     label: 'Roth Conversions',color: '#3b82f6', source: 'taxable_income_breakdown' }
    ];

    this.update = this.update.bind(this);
    window.addEventListener('profile:updated', this.update);

    this.render();
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy();
    }
    window.removeEventListener('profile:updated', this.update);
  }

  update(event) {
    const results = event.detail.results;
    this.chartData = results.fill_bracket_results.yearly;
    this.render();
    this.updateTable(this.chartData);
  }

  updateTable(data) {
    const tbody = this.tableTarget.querySelector('tbody');
    tbody.innerHTML = '';
    data.forEach(row => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${row.year}</td>
        <td>${row.age}</td>
        <td>${this.formatCurrency(row.total_gross_income)}</td>
        <td>${this.formatCurrency(row.total_tax)}</td>
        <td>${this.formatCurrency(row.ending_net_worth)}</td>
      `;
      tbody.appendChild(tr);
    });
  }

  formatCurrency(number) {
    return new Intl.NumberFormat('en-US', { 
      style: 'currency', 
      currency: 'USD', 
      minimumFractionDigits: 0, 
      maximumFractionDigits: 0 
    }).format(number);
  }

  toggle() {
    this.tableTarget.classList.toggle('hidden');
  }

  render() {
    // Destroy existing chart if it exists
    if (this.chart) {
      this.chart.destroy();
    }

    // Prepare datasets for stacked area chart
    const datasets = this.chartConfig.map(config => {
      return {
        label: config.label,
        data: this.chartData.map(d => d[config.source][config.key] || 0),
        backgroundColor: config.color,
        borderColor: config.color,
        borderWidth: 1,
        fill: true
      };
    });

    const labels = this.chartData.map(d => d.year);

    // Create the chart
    const ctx = this.canvasTarget.getContext('2d');
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: {
            display: true,
            position: 'bottom',
            labels: {
              usePointStyle: true,
              padding: 15,
              font: {
                size: 12
              }
            }
          },
          tooltip: {
            mode: 'index',
            callbacks: {
              label: (context) => {
                const label = context.dataset.label || '';
                const value = this.formatCurrency(context.parsed.y);
                return `${label}: ${value}`;
              },
              footer: (tooltipItems) => {
                const total = tooltipItems.reduce((sum, item) => sum + item.parsed.y, 0);
                return `Total: ${this.formatCurrency(total)}`;
              }
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              maxRotation: 0,
              autoSkip: true,
              maxTicksLimit: 10
            }
          },
          y: {
            stacked: true,
            beginAtZero: true,
            grid: {
              color: '#e5e7eb',
              drawBorder: false
            },
            ticks: {
              callback: (value) => {
                return '$' + (value / 1000).toFixed(0) + 'k';
              }
            }
          }
        }
      }
    });
  }
}
