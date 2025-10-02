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
      
    } catch (error) {
      console.error('Error running simulation:', error);
      alert('Failed to update simulation. Please check your inputs and try again.');
    }
  }
}
