window.addEventListener('DOMContentLoaded', () => {
  // A Stimulus controller to render a simple, Tufte-an SVG chart
  // This controller avoids heavy libraries in favor of clarity and minimalism.
  class ChartController extends Stimulus.Controller {
    static get targets() {
      return ["table", "container"]
    }

    connect() {
      const chartJSON = JSON.parse(document.getElementById('simulation-data').textContent);
      this.chartData = chartJSON.fill_bracket; // Focus on the more interesting strategy
      this.tableTarget.classList.add('hidden');
      this.render();
    }

    toggle() {
      this.tableTarget.classList.toggle('hidden');
    }

    render() {
      const width = this.containerTarget.clientWidth;
      const height = this.containerTarget.clientHeight;
      const margin = { top: 20, right: 20, bottom: 30, left: 50 };

      const maxIncome = Math.max(...this.chartData.map(d => Object.values(d.income_sources).reduce((a, b) => a + b, 0) + d.taxable_income_breakdown.conversions));

      const xScale = (year) => margin.left + (year - this.chartData[0].year) * (width - margin.left - margin.right) / (this.chartData.length - 1);
      const yScale = (income) => height - margin.bottom - (income / maxIncome) * (height - margin.top - margin.bottom);
      const yScaleInverse = (y) => (maxIncome * ((height - margin.bottom) - y)) / (height - margin.top - margin.bottom);

      const svg = this.createSVGElement('svg', { width, height });

      // --- Create Stacked Area Paths ---
      const incomeKeys = ['social_security', 'rmd', 'withdrawals'];
      let lastY = new Array(this.chartData.length).fill(height - margin.bottom);

      const colors = { social_security: '#a3e635', rmd: '#6b7280', withdrawals: '#f97316', conversions: '#3b82f6' };

      // Stacked areas for income sources
      incomeKeys.forEach(key => {
        const pathData = this.chartData.map((d, i) => {
          const yValue = d.income_sources[key] || 0;
          const newY = yScale(yScaleInverse(lastY[i]) + yValue);
          const point = `${xScale(d.year)},${newY}`;
          lastY[i] = newY;
          return point;
        }).join(' ');

        const areaPath = `M${xScale(this.chartData[0].year)},${height - margin.bottom} L${pathData} L${xScale(this.chartData[this.chartData.length - 1].year)},${height - margin.bottom}`;
        svg.appendChild(this.createSVGElement('path', { d: areaPath, fill: colors[key], opacity: 0.7 }));
      });

      // Add conversions on top
      const pathData = this.chartData.map((d, i) => {
        const yValue = d.taxable_income_breakdown.conversions || 0;
        const newY = yScale(yScaleInverse(lastY[i]) + yValue);
        const point = `${xScale(d.year)},${newY}`;
        lastY[i] = newY;
        return point;
      }).join(' ');
      const areaPath = `M${xScale(this.chartData[0].year)},${height - margin.bottom} L${pathData} L${xScale(this.chartData[this.chartData.length - 1].year)},${height - margin.bottom}`;
      svg.appendChild(this.createSVGElement('path', { d: areaPath, fill: colors['conversions'], opacity: 0.7 }));

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