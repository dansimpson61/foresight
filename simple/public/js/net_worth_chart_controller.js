// A Stimulus controller to render a stacked area chart of net worth over time
class NetWorthChartController extends Stimulus.Controller {
  static targets = ["canvas"]

  connect() {
    const chartJSON = JSON.parse(document.getElementById('simulation-data').textContent);
    // We'll chart the 'fill_bracket' scenario by default
    this.chartData = chartJSON.fill_bracket;

    this.chartConfig = [
      { key: 'taxable',     label: 'Taxable',     color: '#3b82f6' },
      { key: 'roth',        label: 'Roth',        color: '#16a34a' },
      { key: 'traditional', label: 'Traditional', color: '#f97316' }
    ];

  this.update = this.update.bind(this);
  window.addEventListener('profile:updated', this.update);
  window.addEventListener('simulation:updated', this.update);

    this.render();
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy();
    }
  window.removeEventListener('profile:updated', this.update);
  window.removeEventListener('simulation:updated', this.update);
  }

  update(event) {
    const results = event.detail.results;
    const strategy = (event.detail && event.detail.strategy) || 'fill_to_bracket';
    const yearly = strategy === 'do_nothing' 
      ? results.do_nothing_results.yearly 
      : results.fill_bracket_results.yearly;
    this.chartData = yearly;
    this.render();
  }

  render() {
    if (this.chart) {
      this.chart.destroy();
    }

    const datasets = this.chartConfig.map(config => {
      return {
        label: config.label,
        data: this.chartData.map(d => d.ending_balances[config.key] || 0),
        backgroundColor: config.color,
        borderColor: config.color,
        borderWidth: 1,
        fill: true
      };
    });

    const labels = this.chartData.map(d => d.year);

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
            position: 'bottom'
          },
          tooltip: {
            mode: 'index',
            callbacks: {
              label: (context) => {
                const label = context.dataset.label || '';
                const value = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(context.parsed.y);
                return `${label}: ${value}`;
              }
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { maxRotation: 0, autoSkip: true, maxTicksLimit: 10 }
          },
          y: {
            stacked: true,
            beginAtZero: true,
            grid: { color: '#e5e7eb', drawBorder: false },
            ticks: {
              callback: (value) => '$' + (value / 1000).toFixed(0) + 'k'
            }
          }
        }
      }
    });
  }
}