import { Controller } from "/vendor/stimulus.js";

export default class extends Controller {
  static targets = ["input", "strategy", "download"];

  connect() {
    this.model = null;
  }

  setState(state) {
    const el = document.getElementById('ui-state');
    if (el) el.setAttribute('data-state', state);
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
