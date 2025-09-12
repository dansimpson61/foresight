import { Controller } from "/vendor/stimulus.js";

export default class extends Controller {
  static targets = ["input", "strategy", "download", "startYear", "years", "inflation", "growth", "bracket"];

  connect() {
    this.model = null;
    // Initialize textarea from controls if empty
    if (this.hasStartYearTarget && this.inputTarget && !this.inputTarget.value.trim()) {
      this.syncJsonFromControls();
    }
    // Debounce timer holder
    this._debounce = null;
  }

  setState(state) {
    const el = document.getElementById('ui-state');
    if (el) el.setAttribute('data-state', state);
  }

  onControlsChanged() {
    // Update JSON from form controls, then debounce auto-run
    this.syncJsonFromControls();
    clearTimeout(this._debounce);
    this._debounce = setTimeout(() => this.runPlan(), 400);
  }

  syncJsonFromControls() {
    try {
      const current = this.inputTarget.value.trim() ? JSON.parse(this.inputTarget.value) : {};
      const start_year = this.hasStartYearTarget ? Number(this.startYearTarget.value) : current.start_year;
      const years = this.hasYearsTarget ? Number(this.yearsTarget.value) : current.years;
      const inflation_rate = this.hasInflationTarget ? Number(this.inflationTarget.value) / 100.0 : (current.inflation_rate ?? 0.0);
  const desired_tax_bracket_ceiling = this.hasBracketTarget ? Number(this.bracketTarget.value) : (current.desired_tax_bracket_ceiling ?? 0);
  const assumed_growth_rate = this.hasGrowthTarget ? Number(this.growthTarget.value) / 100.0 : (current.assumed_growth_rate ?? 0.05);
      // Preserve members/accounts/income_sources if present; otherwise keep from example once loaded
      const next = Object.assign({}, current, {
        start_year,
        years,
        inflation_rate,
        desired_tax_bracket_ceiling,
        assumed_growth_rate,
      });
      this.inputTarget.value = JSON.stringify(next, null, 2);
    } catch (e) {
      // If JSON invalid, rebuild a minimal shell from controls
      const next = {
        members: [],
        accounts: [],
        income_sources: [],
        start_year: this.hasStartYearTarget ? Number(this.startYearTarget.value) : 2025,
        years: this.hasYearsTarget ? Number(this.yearsTarget.value) : 35,
        inflation_rate: this.hasInflationTarget ? Number(this.inflationTarget.value) / 100.0 : 0.0,
        desired_tax_bracket_ceiling: this.hasBracketTarget ? Number(this.bracketTarget.value) : 0,
        assumed_growth_rate: this.hasGrowthTarget ? Number(this.growthTarget.value) / 100.0 : 0.05,
      };
      this.inputTarget.value = JSON.stringify(next, null, 2);
    }
  }

  async loadExample() {
    try {
      window.showToast('Loading example…', 'info', 900);
      const r = await fetch('/plan/example', { headers: { Accept: 'application/json' } });
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      const j = await r.json();
      this.inputTarget.value = JSON.stringify(j, null, 2);
      this.setState('example-loaded');
      window.showToast('Loaded example ✓', 'success');
    } catch (err) {
      this.inputTarget.value = `// Failed to load example: ${err}`;
      window.showToast('Failed to load example', 'error');
      console.error('Load example failed', err);
    }
  }

  async runPlan() {
    try {
      const body = JSON.parse(this.inputTarget.value);
      const r = await fetch('/plan', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
      const t = await r.text();
      this.lastJsonText = t;
      this.model = JSON.parse(t);
      const keys = Object.keys(this.model.data.results);
      this.populateStrategy(keys);
      this.strategyTarget.value = keys[0];
      this.updateView(keys[0]);
      this.enableDownload();
      this.setState('plan-ready');
      window.showToast('Plan calculated ✓', 'success');
    } catch (e) {
      // Avoid blocking alert in tests, prefer toast
      window.showToast('Plan failed — check JSON', 'error');
      console.error('Run plan failed', e);
    }
  }

  changeStrategy() {
    this.updateView(this.strategyTarget.value);
  }

  populateStrategy(keys) {
    this.strategyTarget.innerHTML = '';
    keys.forEach((k) => {
      const opt = document.createElement('option');
      opt.value = k; opt.textContent = k; this.strategyTarget.appendChild(opt);
    });
    this.strategyTarget.disabled = keys.length === 0;
  }

  updateView(strategyKey) {
    if (!this.model) return;
    const bundle = this.model.data.results[strategyKey];
    this.dispatch('results', { detail: bundle });
  }

  enableDownload() {
    if (!this.hasDownloadTarget || !this.lastJsonText) return;
    const btn = this.downloadTarget;
    btn.disabled = false;
    btn.onclick = () => {
      const blob = new Blob([this.lastJsonText], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = 'foresight_report.json'; a.click();
      URL.revokeObjectURL(url);
    };
  }
}
