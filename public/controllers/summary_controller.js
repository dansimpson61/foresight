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
    static targets = ['netWorth', 'taxable', 'roth', 'pretax', 'lifetimeIRMAA'];

    connect() {
        document.addEventListener('plan:results', this.update.bind(this));
    }

    update(event) {
        const results = event.detail?.results;
        const yearlyData = results?.yearly;
        const aggregateData = results?.aggregate;

        if (!Array.isArray(yearlyData) || yearlyData.length === 0) {
            console.warn('Yearly results for summary is not an array or is empty.');
            this.clearSummary();
            return;
        }

        const lastYear = yearlyData[yearlyData.length - 1];
        if (!lastYear) {
            this.clearSummary();
            return;
        }

        this.netWorthTarget.textContent = formatToUSDCurrency(lastYear.ending_net_worth);
        this.taxableTarget.textContent = formatToUSDCurrency(lastYear.ending_taxable_balance);
        this.rothTarget.textContent = formatToUSDCurrency(lastYear.ending_roth_balance);
        this.pretaxTarget.textContent = formatToUSDCurrency(lastYear.ending_traditional_balance);
        
        if (aggregateData) {
            this.lifetimeIRMAATarget.textContent = formatToUSDCurrency(aggregateData.cumulative_irmaa_surcharges);
        } else {
            this.lifetimeIRMAATarget.textContent = 'N/A';
        }
    }

    clearSummary() {
        this.netWorthTarget.textContent = 'N/A';
        this.taxableTarget.textContent = 'N/A';
        this.rothTarget.textContent = 'N/A';
        this.pretaxTarget.textContent = 'N/A';
        this.lifetimeIRMAATarget.textContent = 'N/A';
    }
}
