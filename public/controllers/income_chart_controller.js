import { Controller } from 'stimulus';

export default class extends Controller {
  static targets = ["container"];

  connect() {
    document.addEventListener('plan:results', this.render.bind(this));
  }

  render(event) {
    const results = event.detail?.results;
    if (!results || !Array.isArray(results.yearly) || results.yearly.length === 0) {
      this.containerTarget.innerHTML = '<p>No data to display.</p>';
      return;
    }
    
    const svg = this.createSvgChart(results.yearly);
    this.containerTarget.innerHTML = svg;
  }

  createSvgChart(yearlyData) {
    const width = 800;
    const height = 400;
    const margin = { top: 20, right: 20, bottom: 30, left: 50 };
    const chartWidth = width - margin.left - margin.right;
    const chartHeight = height - margin.top - margin.bottom;

    const labels = yearlyData.map(d => d.year);
    const maxVal = Math.max(...yearlyData.map(d => Object.values(d.taxable_income_breakdown).reduce((a, b) => a + b, 0)));
    
    const xScale = (index) => margin.left + (index * (chartWidth / labels.length));
    const yScale = (value) => height - margin.bottom - (value / maxVal * chartHeight);
    
    const incomeSources = ['salaries', 'pensions', 'ss_benefits', 'rmds', 'spending_withdrawals_ordinary', 'roth_conversions', 'capital_gains'];
    const incomeColors = {
      salaries: '#4CAF50', pensions: '#81C784', ss_benefits: '#A5D6A7',
      rmds: '#FFB74D', spending_withdrawals_ordinary: '#FF8A65',
      roth_conversions: '#E57373', capital_gains: '#BA68C8'
    };

    let bars = '';
    yearlyData.forEach((year, i) => {
      let yOffset = 0;
      incomeSources.forEach(source => {
        const val = year.taxable_income_breakdown[source] || 0;
        const barHeight = (val / maxVal * chartHeight);
        if (barHeight > 0) {
          bars += `<rect x="${xScale(i)}" y="${yScale(yOffset + val)}" width="${chartWidth / labels.length - 5}" height="${barHeight}" fill="${incomeColors[source]}"><title>${source}: ${val}</title></rect>\n`;
          yOffset += val;
        }
      });
    });

    const taxBrackets = yearlyData[0].tax_brackets;
    const standardDeduction = taxBrackets.standard_deduction;
    const bracketCeilings = taxBrackets.brackets.map(b => b.ceiling + standardDeduction);
    const bracketColors = ['#64B5F6', '#42A5F5', '#2196F3', '#1E88E5', '#1976D2'];
    
    let lines = `<path d="M${margin.left},${yScale(standardDeduction)} H${width - margin.right}" stroke="#9E9E9E" stroke-dasharray="5,5" />\n`;
    bracketCeilings.forEach((ceiling, i) => {
      lines += `<path d="M${margin.left},${yScale(ceiling)} H${width - margin.right}" stroke="${bracketColors[i]}" />\n`;
    });
    
    return `
      <svg width="${width}" height="${height}" font-family="sans-serif" font-size="10">
        <g class="bars">${bars}</g>
        <g class="lines">${lines}</g>
      </svg>
    `;
  }
}
