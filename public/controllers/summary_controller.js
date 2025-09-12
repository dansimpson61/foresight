import { Controller } from "https://unpkg.com/@hotwired/stimulus@3.2.2/dist/stimulus.js";

export default class extends Controller {
  static targets = ["lifetimeTaxes", "totalConversions", "endNetWorth", "taxFreePct"];

  connect() {
    this.element.addEventListener('plan-form:results', (e) => this.render(e.detail));
  }

  fmtMoney(n) {
    if (n == null || isNaN(n)) return '--';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(Number(n));
  }
  fmtPct(n) {
    return n == null || isNaN(n) ? '--' : `${(Number(n) * 100).toFixed(1)}%`;
  }

  render(bundle) {
    const agg = bundle.aggregate || {};
    const lifetime = agg.cumulative_all_in_tax ?? (agg.cumulative_federal_tax + agg.cumulative_capital_gains_tax);
    this.lifetimeTaxesTarget.textContent = this.fmtMoney(lifetime);
    this.totalConversionsTarget.textContent = this.fmtMoney(agg.cumulative_roth_conversions);
    const endNW = (agg.ending_taxable_balance || 0) + (agg.ending_traditional_balance || 0) + (agg.ending_roth_balance || 0);
    this.endNetWorthTarget.textContent = this.fmtMoney(endNW);
    const taxFreePct = endNW > 0 ? (agg.ending_roth_balance || 0) / endNW : 0;
    this.taxFreePctTarget.textContent = this.fmtPct(taxFreePct);
  }
}
