// A Stimulus controller to manage simulation parameters
// Separate from profile to maintain clear mental model: "who you are" vs "what you're testing"
class SimulationController extends Stimulus.Controller {
  static targets = [
    "form",
    "yearsToSimulate",
    "startYear",
    "inflationRate",
    "traditionalGrowth",
    "rothGrowth",
    "taxableGrowth",
    "cashGrowth",
    "strategy",
    "bracketCeiling"
  ]

  connect() {
    // Load persisted profile and simulation strategy params to prefill
    const store = window.FSUtils && FSUtils.storage;
    const persisted = store ? store.loadJSON('foresight:simple:profile') : null;
    if (persisted) {
      document.getElementById('default-profile-data').textContent = JSON.stringify(persisted);
    }
    const sim = store ? store.loadJSON('foresight:simple:simulation') : null;
    if (sim) {
      if (sim.strategy) this.strategyTarget.value = sim.strategy;
      if (sim.strategy_params && typeof sim.strategy_params.ceiling === 'number') {
        this.bracketCeilingTarget.value = sim.strategy_params.ceiling;
      }
    }
  }

  toggleEditor(event) {
    if (window.FSUtils && FSUtils.toggleExpanded) {
      FSUtils.toggleExpanded(this.formTarget, event && event.currentTarget);
    } else {
      this.formTarget.classList.toggle('hidden');
      if (event && event.currentTarget) {
        const expanded = !this.formTarget.classList.contains('hidden');
        event.currentTarget.setAttribute('aria-expanded', String(expanded));
      }
    }
  }

  save() {
    // Get the current profile
    const baseProfile = JSON.parse(document.getElementById('default-profile-data').textContent);
    
    // Update simulation parameters
    const profile = this.buildProfileWithSimulationParams(baseProfile);

    // Re-run with updated parameters
    this.rerunSimulation(profile);
    
    // Close the editor
    this.formTarget.classList.add('hidden');
  }

  buildProfileWithSimulationParams(baseProfile) {
    // Update simulation settings
    baseProfile.years_to_simulate = parseInt(this.yearsToSimulateTarget.value, 10);
    baseProfile.start_year = parseInt(this.startYearTarget.value, 10);
    baseProfile.inflation_rate = parseFloat(this.inflationRateTarget.value);

    // Update growth assumptions
    baseProfile.growth_assumptions = {
      traditional: parseFloat(this.traditionalGrowthTarget.value),
      roth: parseFloat(this.rothGrowthTarget.value),
      taxable: parseFloat(this.taxableGrowthTarget.value),
      cash: parseFloat(this.cashGrowthTarget.value)
    };

    return baseProfile;
  }

  async rerunSimulation(profile) {
    try {
      const strategy = this.strategyTarget.value;
      const strategyParams = strategy === 'fill_to_bracket' 
        ? { ceiling: parseInt(this.bracketCeilingTarget.value, 10) }
        : {};

      const results = (window.FSUtils && FSUtils.fetchJson)
        ? await FSUtils.fetchJson('/run', { profile, strategy, strategy_params: strategyParams })
        : await (async () => { const r = await fetch('/run', { method:'POST', headers: { 'Content-Type':'application/json','Accept':'application/json' }, body: JSON.stringify({ profile, strategy, strategy_params: strategyParams }) }); if (!r.ok) throw new Error(`HTTP error! status: ${r.status}`); return r.json(); })();

      // Dispatch event to update visualizations
      const event = new CustomEvent('simulation:updated', { 
        detail: { results, profile, strategy, strategyParams } 
      });
      window.dispatchEvent(event);
      // Persist simulation selections for better UX continuity
      if (window.FSUtils && FSUtils.storage) {
        FSUtils.storage.saveJSON('foresight:simple:simulation', { strategy, strategy_params: strategyParams });
        FSUtils.storage.saveJSON('foresight:simple:profile', profile);
      } else {
        try {
          localStorage.setItem('foresight:simple:simulation', JSON.stringify({ strategy, strategy_params: strategyParams }));
          localStorage.setItem('foresight:simple:profile', JSON.stringify(profile));
        } catch (e) {
          console.warn('Could not persist simulation settings.', e);
        }
      }
      
    } catch (error) {
      console.error('Error running simulation:', error);
      alert('Failed to update simulation. Please check your inputs and try again.');
    }
  }

  async resetDefaults() {
    try {
      if (window.FSUtils && FSUtils.fetchJson) {
        await FSUtils.fetchJson('/reset_defaults', {});
      } else {
        const res = await fetch('/reset_defaults', { method: 'POST' });
        if (!res.ok) throw new Error('Failed to reset defaults');
      }
      if (window.FSUtils && FSUtils.storage) {
        FSUtils.storage.remove(['foresight:simple:profile', 'foresight:simple:simulation']);
      } else {
        localStorage.removeItem('foresight:simple:profile');
        localStorage.removeItem('foresight:simple:simulation');
      }
      window.location.reload();
    } catch (e) {
      alert('Could not reset defaults.');
    }
  }

  async saveAsDefaults() {
    try {
      const baseProfile = JSON.parse(document.getElementById('default-profile-data').textContent);
      const profile = this.buildProfileWithSimulationParams(baseProfile);
      const strategy = this.strategyTarget.value;
      const strategyParams = strategy === 'fill_to_bracket' 
        ? { ceiling: parseInt(this.bracketCeilingTarget.value, 10) }
        : {};
      if (window.FSUtils && FSUtils.fetchJson) {
        await FSUtils.fetchJson('/save_defaults', { profile, strategy, strategy_params: strategyParams });
      } else {
        const res = await fetch('/save_defaults', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ profile, strategy, strategy_params: strategyParams }) });
        if (!res.ok) throw new Error('Failed to save defaults');
      }
      alert('Defaults saved for this server.');
    } catch (e) {
      alert('Could not save defaults.');
    }
  }

  async clearServerDefaults() {
    try {
      if (window.FSUtils && FSUtils.fetchJson) {
        await FSUtils.fetchJson('/clear_defaults', {});
      } else {
        const res = await fetch('/clear_defaults', { method: 'POST' });
        if (!res.ok) throw new Error('Failed to clear server defaults');
      }
      if (window.FSUtils && FSUtils.storage) {
        FSUtils.storage.remove(['foresight:simple:profile', 'foresight:simple:simulation']);
      } else {
        localStorage.removeItem('foresight:simple:profile');
        localStorage.removeItem('foresight:simple:simulation');
      }
      window.location.reload();
    } catch (e) {
      alert('Could not clear server defaults.');
    }
  }
}
