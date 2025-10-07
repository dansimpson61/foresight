// A Stimulus controller using Chart.js for clear, maintainable visualization
class ChartController extends Stimulus.Controller {
  static targets = ["table", "canvas", "legend"]

  connect() {
    const chartJSON = JSON.parse(document.getElementById('simulation-data').textContent);
    this.latestResults = { do_nothing_results: { yearly: chartJSON.do_nothing }, fill_bracket_results: { yearly: chartJSON.fill_bracket } };
    this.chartData = this.latestResults.fill_bracket_results.yearly;
    this.tableTarget.classList.add('hidden');

    this.chartConfig = [
      { key: 'social_security', label: 'Social Security', color: 'rgba(163, 230, 53, 0.4)', border: '#7fb235', source: 'income_sources' },
      { key: 'rmd',             label: 'RMDs',            color: 'rgba(107, 114, 128, 0.25)', border: '#6b7280', source: 'income_sources' },
      { key: 'withdrawals',     label: 'Withdrawals',     color: 'rgba(249, 115, 22, 0.25)', border: '#ef7f1a', source: 'income_sources' },
      { key: 'conversions',     label: 'Roth Conversions',color: 'rgba(37, 99, 235, 0.25)', border: '#2563eb', source: 'taxable_income_breakdown' }
    ];

  this.update = this.update.bind(this);
    window.addEventListener('profile:updated', this.update);
    window.addEventListener('simulation:updated', this.update);
    this.handleViz = (e) => {
      const strategy = (e && e.detail && e.detail.strategy) || 'fill_to_bracket';
      const yearly = (window.FSUtils && FSUtils.pickYearly) ? FSUtils.pickYearly(this.latestResults, strategy) : (strategy === 'do_nothing' ? this.latestResults.do_nothing_results.yearly : this.latestResults.fill_bracket_results.yearly);
      this.chartData = yearly;
      this.render();
      this.updateTable(this.chartData);
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
    return (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(number) : number;
  }

  toggle(event) {
    if (window.FSUtils && FSUtils.toggleExpanded) {
      FSUtils.toggleExpanded(this.tableTarget, event && event.currentTarget);
    } else {
      this.tableTarget.classList.toggle('hidden');
      if (event && event.currentTarget) {
        const expanded = !this.tableTarget.classList.contains('hidden');
        event.currentTarget.setAttribute('aria-expanded', String(expanded));
      }
    }
  }

  render() {
    // Destroy existing chart if it exists
    if (window.FSUtils && FSUtils.safeDestroy) { FSUtils.safeDestroy(this.chart); } else { if (this.chart) this.chart.destroy(); }

    // Prepare datasets for stacked area chart
    const datasets = this.chartConfig.map(config => ({
      label: config.label,
      data: this.chartData.map(d => d[config.source][config.key] || 0),
      backgroundColor: config.color,
      borderColor: config.border,
      borderWidth: 1,
      pointRadius: 0,
      pointHoverRadius: 2,
      fill: true
    }));

    const labels = this.chartData.map(d => d.year);

    // Create the chart
    const ctx = this.canvasTarget.getContext('2d');
    const options = (window.FSUtils && FSUtils.createChartOptions) ? FSUtils.createChartOptions({
      legend: { display: true, position: 'bottom', labels: { usePointStyle: false, padding: 8, font: { size: 12 } } },
      tooltipLabel: (context) => {
        const label = context.dataset.label || '';
        const value = this.formatCurrency(context.parsed.y);
        return `${label}: ${value}`;
      },
      tooltipFooter: (tooltipItems) => {
        const total = tooltipItems.reduce((sum, item) => sum + item.parsed.y, 0);
        return `Total: ${this.formatCurrency(total)}`;
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
