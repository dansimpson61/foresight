import { Controller } from "/vendor/stimulus.js";

export default class extends Controller {
  static targets = ["table"];

  connect() {
    this.element.addEventListener('plan-form:results', (e) => this.render(e.detail));
  }

  fmtMoney(n) {
    if (n == null || isNaN(n)) return '--';
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(Number(n));
  }

  render(bundle) {
    const yearly = bundle.yearly || [];
    const tbody = this.tableTarget.querySelector('tbody');
    tbody.innerHTML = '';
    yearly.forEach((r) => {
      const tr = document.createElement('tr');
      const cells = [
        r.year,
        this.fmtMoney(r.actual_roth_conversion),
        this.fmtMoney(r.federal_tax),
        this.fmtMoney(r.state_tax),
        this.fmtMoney(r.capital_gains_tax),
        this.fmtMoney(r.all_in_tax),
        this.fmtMoney(r.magi),
        this.fmtMoney(r.irmaa_part_b),
        this.fmtMoney(r.ending_taxable_balance),
        this.fmtMoney(r.ending_traditional_balance),
        this.fmtMoney(r.ending_roth_balance),
        (r.events && r.events.length) || 0,
      ];
      cells.forEach((v) => {
        const td = document.createElement('td');
        td.textContent = v;
        td.style.textAlign = 'right';
        td.style.borderBottom = '1px solid #eee';
        td.style.padding = '4px 6px';
        tr.appendChild(td);
      });
      tbody.appendChild(tr);
    });
  }
}
