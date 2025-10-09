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
    "bracketCeiling",
    "ssClaimingAge"
  ]

  connect() {
    // Load persisted profile and simulation strategy params to prefill
    // No client-side persistence; use server-provided defaults embedded in the page
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

    // Update SS claiming ages (now part of simulation decisions UI)
    if (this.hasSsClaimingAgeTargets) {
      this.ssClaimingAgeTargets.forEach(input => {
        const memberIndex = parseInt(input.dataset.memberIndex, 10);
        const memberName = baseProfile.members[memberIndex].name;
        const srcIndex = baseProfile.income_sources.findIndex(s => s.type === 'social_security' && s.recipient === memberName);
        if (srcIndex >= 0) baseProfile.income_sources[srcIndex].claiming_age = parseInt(input.value, 10);
      });
    }

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
        : await (async () => { const u=(window.FSUtils&&FSUtils.withBase)?FSUtils.withBase('/run'):'/run'; const r = await fetch(u, { method:'POST', headers: { 'Content-Type':'application/json','Accept':'application/json' }, body: JSON.stringify({ profile, strategy, strategy_params: strategyParams }) }); if (!r.ok) throw new Error(`HTTP error! status: ${r.status}`); return r.json(); })();

      // Dispatch event to update visualizations
      const event = new CustomEvent('simulation:updated', { 
        detail: { results, profile, strategy, strategyParams } 
      });
      window.dispatchEvent(event);
      // No client persistence; keep state server-side only
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
        const u=(window.FSUtils&&FSUtils.withBase)?FSUtils.withBase('/reset_defaults'):'/reset_defaults';
        const res = await fetch(u, { method: 'POST' });
        if (!res.ok) throw new Error('Failed to reset defaults');
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
        const u=(window.FSUtils&&FSUtils.withBase)?FSUtils.withBase('/save_defaults'):'/save_defaults';
        const res = await fetch(u, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ profile, strategy, strategy_params: strategyParams }) });
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
        const u=(window.FSUtils&&FSUtils.withBase)?FSUtils.withBase('/clear_defaults'):'/clear_defaults';
        const res = await fetch(u, { method: 'POST' });
        if (!res.ok) throw new Error('Failed to clear server defaults');
      }
      window.location.reload();
    } catch (e) {
      alert('Could not clear server defaults.');
    }
  }
}
