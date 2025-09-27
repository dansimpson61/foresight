window.addEventListener('DOMContentLoaded', () => {
  // A Stimulus controller to render a simple, Tufte-an SVG chart
  // This controller avoids heavy libraries in favor of clarity and minimalism.
  class ChartController extends Stimulus.Controller {
    static get targets() {
      return ["table", "container", "legend"]
    }

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
      this.renderLegend();
    }

    disconnect() {
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
      return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(number);
    }

    toggle() {
      this.tableTarget.classList.toggle('hidden');
    }

    renderLegend() {
      this.legendTarget.innerHTML = '';
      this.chartConfig.forEach(config => {
        const item = document.createElement('div');
        item.className = 'legend-item';

        const swatch = document.createElement('span');
        swatch.className = 'legend-swatch';
        swatch.style.backgroundColor = config.color;

        const text = document.createElement('span');
        text.textContent = config.label;

        item.appendChild(swatch);
        item.appendChild(text);
        this.legendTarget.appendChild(item);
      });
    }

    render() {
      const width = this.containerTarget.clientWidth;
      const height = this.containerTarget.clientHeight;
      const margin = { top: 20, right: 20, bottom: 30, left: 50 };

      const maxIncome = Math.max(...this.chartData.map(d =>
        this.chartConfig.reduce((sum, config) => sum + (d[config.source][config.key] || 0), 0)
      ));

      const xScale = (year) => margin.left + (year - this.chartData[0].year) * (width - margin.left - margin.right) / (this.chartData.length - 1);
      const yScale = (income) => height - margin.bottom - (income / maxIncome) * (height - margin.top - margin.bottom);

      const svg = this.createSVGElement('svg', { width, height });
      let lastYValues = new Array(this.chartData.length).fill(0);

      // --- Create Stacked Area Paths ---
      this.chartConfig.forEach(config => {
        const currentYValues = [];
        const topPoints = this.chartData.map((d, i) => {
          const yValue = d[config.source][config.key] || 0;
          currentYValues[i] = lastYValues[i] + yValue;
          return { x: xScale(d.year), y: yScale(currentYValues[i]) };
        });

        const bottomPoints = lastYValues.map((y, i) => {
          return { x: xScale(this.chartData[i].year), y: yScale(y) };
        });

        const pathData = topPoints.map(p => `L${p.x},${p.y}`).join('');
        const bottomPathDataReversed = bottomPoints.reverse().map(p => `L${p.x},${p.y}`).join('');

        const areaPath = `M${topPoints[0].x},${topPoints[0].y}${pathData}${bottomPathDataReversed}Z`;

        svg.appendChild(this.createSVGElement('path', { d: areaPath, fill: config.color, opacity: 0.8 }));

        lastYValues = currentYValues;
      });

      // --- Create Axes ---
      // Y-Axis
      for (let i = 0; i <= 5; i++) {
          const income = (maxIncome / 5) * i;
          svg.appendChild(this.createSVGElement('line', { x1: margin.left, y1: yScale(income), x2: width - margin.right, y2: yScale(income), stroke: '#e5e7eb' }));
          svg.appendChild(this.createSVGElement('text', { x: margin.left - 10, y: yScale(income) + 5, 'text-anchor': 'end', fill: '#6b7280', 'font-size': '12px' }, `$${(income/1000).toFixed(0)}k`));
      }
      // X-Axis
      this.chartData.forEach((d, i) => {
          if (i % 5 === 0) {
              svg.appendChild(this.createSVGElement('text', { x: xScale(d.year), y: height - margin.bottom + 15, 'text-anchor': 'middle', fill: '#6b7280', 'font-size': '12px' }, d.year));
          }
      });

      this.containerTarget.innerHTML = '';
      this.containerTarget.appendChild(svg);
    }

    createSVGElement(tag, attrs, textContent = '') {
      const el = document.createElementNS('http://www.w3.org/2000/svg', tag);
      for (const key in attrs) {
        el.setAttribute(key, attrs[key]);
      }
      if (textContent) {
        el.textContent = textContent;
      }
      return el;
    }
  }

  // Start the Stimulus application and register the controller
  const application = Stimulus.Application.start();
  application.register("chart", ChartController);
});