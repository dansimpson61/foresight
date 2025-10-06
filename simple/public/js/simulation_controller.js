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
    try {
      const rawProfile = localStorage.getItem('foresight:simple:profile');
      if (rawProfile) {
        const persisted = JSON.parse(rawProfile);
        document.getElementById('default-profile-data').textContent = JSON.stringify(persisted);
      }
      const rawSim = localStorage.getItem('foresight:simple:simulation');
      if (rawSim) {
        const sim = JSON.parse(rawSim);
        if (sim.strategy) this.strategyTarget.value = sim.strategy;
        if (sim.strategy_params && typeof sim.strategy_params.ceiling === 'number') {
          this.bracketCeilingTarget.value = sim.strategy_params.ceiling;
        }
      }
    } catch (e) {
      console.warn('Could not load persisted simulation settings.', e);
    }
  }

  toggleEditor() {
    this.formTarget.classList.toggle('hidden');
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

      const response = await fetch('/run', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          profile: profile,
          strategy: strategy,
          strategy_params: strategyParams
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const results = await response.json();

      // Dispatch event to update visualizations
      const event = new CustomEvent('simulation:updated', { 
        detail: { results, profile, strategy, strategyParams } 
      });
      window.dispatchEvent(event);
      // Persist simulation selections for better UX continuity
      try {
        localStorage.setItem('foresight:simple:simulation', JSON.stringify({ strategy, strategy_params: strategyParams }));
        localStorage.setItem('foresight:simple:profile', JSON.stringify(profile));
      } catch (e) {
        console.warn('Could not persist simulation settings.', e);
      }
      
    } catch (error) {
      console.error('Error running simulation:', error);
      alert('Failed to update simulation. Please check your inputs and try again.');
    }
  }

  async resetDefaults() {
    try {
      const res = await fetch('/reset_defaults', { method: 'POST' });
      if (!res.ok) throw new Error('Failed to reset defaults');
      localStorage.removeItem('foresight:simple:profile');
      localStorage.removeItem('foresight:simple:simulation');
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
      const res = await fetch('/save_defaults', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ profile, strategy, strategy_params: strategyParams })
      });
      if (!res.ok) throw new Error('Failed to save defaults');
      alert('Defaults saved for this server.');
    } catch (e) {
      alert('Could not save defaults.');
    }
  }

  async clearServerDefaults() {
    try {
      const res = await fetch('/clear_defaults', { method: 'POST' });
      if (!res.ok) throw new Error('Failed to clear server defaults');
      localStorage.removeItem('foresight:simple:profile');
      localStorage.removeItem('foresight:simple:simulation');
      window.location.reload();
    } catch (e) {
      alert('Could not clear server defaults.');
    }
  }
}
