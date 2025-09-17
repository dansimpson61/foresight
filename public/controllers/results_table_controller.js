import { Controller } from '../vendor/stimulus.js';

function formatToUSDCurrency(number) {
  if (number === null || typeof number === 'undefined' || isNaN(number)) {
    return 'N/A';
  }
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(number);
}

export default class extends Controller {
  static targets = ['body', 'rowTemplate'];

  connect() {
    document.addEventListener('plan:results', this.render.bind(this));
  }

  render(event) {
    const results = event.detail?.results?.yearly;
    this.bodyTarget.innerHTML = '';

    if (!Array.isArray(results)) {
        console.warn('Yearly results data is not an array or is missing.');
        this.bodyTarget.innerHTML = '<tr><td colspan="5">No data available to display.</td></tr>';
        return;
    }

    results.forEach(yearData => {
      if (!yearData) return;

      const row = this.rowTemplateTarget.content.cloneNode(true);

      const year = yearData.year ?? 'N/A';
      const startingBalance = yearData.starting_balance;
      const endingBalance = yearData.ending_balance;
      const netWorth = yearData.ending_net_worth;
      const tax = yearData.federal_tax;

      row.querySelector('.year').textContent = year;
      row.querySelector('.starting-balance').textContent = formatToUSDCurrency(startingBalance);
      row.querySelector('.ending-balance').textContent = formatToUSDCurrency(endingBalance);
      row.querySelector('.net-worth').textContent = formatToUSDCurrency(netWorth);
      row.querySelector('.tax').textContent = formatToUSDCurrency(tax);

      this.bodyTarget.appendChild(row);
    });
  }
}
