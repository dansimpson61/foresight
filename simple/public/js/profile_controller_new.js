// A Stimulus controller to manage the editable financial profile
// No localStorage - embracing ephemerality and honesty
class ProfileController extends Stimulus.Controller {
  static targets = [
    "form",
    "dateOfBirth",
    "traditionalBalance",
    "rothBalance",
    "taxableBalance",
    "cashBalance",
    "piaAnnual",
    "claimingAge",
    "annualExpenses",
    "filingStatus"
  ]

  toggleEditor() {
    this.formTarget.classList.toggle('hidden');
  }

  save() {
    // Build the complete profile from form inputs
    const profile = this.buildProfileFromForm();

    // Re-run the simulation with the updated profile
    this.rerunSimulation(profile);
    
    // Close the editor
    this.formTarget.classList.add('hidden');
  }

  buildProfileFromForm() {
    // Start with the base profile structure from the page
    const baseProfile = JSON.parse(document.getElementById('default-profile-data').textContent);

    // Update with form values
    baseProfile.members[0].date_of_birth = this.dateOfBirthTarget.value;
    
    // Update account balances
    const trad = baseProfile.accounts.find(a => a.type === 'traditional');
    const roth = baseProfile.accounts.find(a => a.type === 'roth');
    const taxable = baseProfile.accounts.find(a => a.type === 'taxable');
    const cash = baseProfile.accounts.find(a => a.type === 'cash');
    
    if (trad) trad.balance = parseInt(this.traditionalBalanceTarget.value, 10);
    if (roth) roth.balance = parseInt(this.rothBalanceTarget.value, 10);
    if (taxable) taxable.balance = parseInt(this.taxableBalanceTarget.value, 10);
    if (cash) cash.balance = parseInt(this.cashBalanceTarget.value, 10);

    // Update income sources
    const ss = baseProfile.income_sources.find(s => s.type === 'social_security');
    if (ss) {
      ss.pia_annual = parseInt(this.piaAnnualTarget.value, 10);
      ss.claiming_age = parseInt(this.claimingAgeTarget.value, 10);
    }

    // Update household
    baseProfile.household.annual_expenses = parseInt(this.annualExpensesTarget.value, 10);
    baseProfile.household.filing_status = this.filingStatusTarget.value;

    return baseProfile;
  }

  async rerunSimulation(profile) {
    try {
      const response = await fetch('/run', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(profile)
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const results = await response.json();

      // Dispatch event to update all visualizations
      const event = new CustomEvent('profile:updated', { 
        detail: { results, profile } 
      });
      window.dispatchEvent(event);
      
    } catch (error) {
      console.error('Error running simulation:', error);
      alert('Failed to update simulation. Please check your inputs and try again.');
    }
  }
}
