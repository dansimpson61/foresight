// A Stimulus controller to render a stacked area chart of net worth over time
class NetWorthChartController extends Stimulus.Controller {
  static targets = ["canvas"]

  connect() {
    const chartJSON = JSON.parse(document.getElementById('simulation-data').textContent);
    // We'll chart the 'fill_bracket' scenario by default
    this.latestResults = { do_nothing_results: { yearly: chartJSON.do_nothing }, fill_bracket_results: { yearly: chartJSON.fill_bracket } };
    this.chartData = this.latestResults.fill_bracket_results.yearly;

    this.chartConfig = [
      { key: 'taxable',     label: 'Taxable',     color: 'rgba(37, 99, 235, 0.25)', border: '#2563eb' },
      { key: 'roth',        label: 'Roth',        color: 'rgba(22, 163, 74, 0.25)', border: '#16a34a' },
      { key: 'traditional', label: 'Traditional', color: 'rgba(249, 115, 22, 0.25)', border: '#ef7f1a' }
    ];

  this.update = this.update.bind(this);
  window.addEventListener('profile:updated', this.update);
  window.addEventListener('simulation:updated', this.update);
  this.handleViz = (e) => {
    const strategy = (e && e.detail && e.detail.strategy) || 'fill_to_bracket';
    const yearly = (window.FSUtils && FSUtils.pickYearly) ? FSUtils.pickYearly(this.latestResults, strategy) : (strategy === 'do_nothing' ? this.latestResults.do_nothing_results.yearly : this.latestResults.fill_bracket_results.yearly);
    this.chartData = yearly;
    this.render();
  };
  window.addEventListener('visualization:changed', this.handleViz);

    this.render();
  }

  disconnect() {
    if (window.FSUtils && FSUtils.safeDestroy) { FSUtils.safeDestroy(this.chart); } else { if (this.chart) this.chart.destroy(); }
  window.removeEventListener('profile:updated', this.update);
  window.removeEventListener('simulation:updated', this.update);
  window.removeEventListener('visualization:changed', this.handleViz);
  }

  update(event) {
    const results = event.detail.results;
    this.latestResults = results;
    const strategy = (event.detail && event.detail.strategy) || 'fill_to_bracket';
    this.chartData = (window.FSUtils && FSUtils.pickYearly) ? FSUtils.pickYearly(results, strategy) : (strategy === 'do_nothing' ? results.do_nothing_results.yearly : results.fill_bracket_results.yearly);
    this.render();
  }

  render() {
    if (window.FSUtils && FSUtils.safeDestroy) { FSUtils.safeDestroy(this.chart); } else { if (this.chart) this.chart.destroy(); }

    const datasets = this.chartConfig.map(config => ({
      label: config.label,
      data: this.chartData.map(d => d.ending_balances[config.key] || 0),
      backgroundColor: config.color,
      borderColor: config.border,
      borderWidth: 1,
      pointRadius: 0,
      pointHoverRadius: 2,
      fill: true
    }));

    const labels = this.chartData.map(d => d.year);

    const ctx = this.canvasTarget.getContext('2d');
    const options = (window.FSUtils && FSUtils.createChartOptions) ? FSUtils.createChartOptions({
      legend: { display: true, position: 'bottom' },
      tooltipLabel: (context) => {
        const label = context.dataset.label || '';
        const value = (window.FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(context.parsed.y) : context.parsed.y;
        return `${label}: ${value}`;
      },
      yTick: (value) => '$' + (value / 1000).toFixed(0) + 'k',
      xMaxTicksLimit: 10,
    }) : {};

    this.chart = new Chart(ctx, {
      type: 'line',
      data: { labels, datasets },
      options
    });
  }
}