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
    
    // Update account balances - preserving all account properties
    const trad = baseProfile.accounts.find(a => a.type === 'traditional');
    const roth = baseProfile.accounts.find(a => a.type === 'roth');
    const taxable = baseProfile.accounts.find(a => a.type === 'taxable');
    const cash = baseProfile.accounts.find(a => a.type === 'cash');
    
    if (trad) trad.balance = parseFloat(this.traditionalBalanceTarget.value);
    if (roth) roth.balance = parseFloat(this.rothBalanceTarget.value);
    if (taxable) taxable.balance = parseFloat(this.taxableBalanceTarget.value);
    if (cash) cash.balance = parseFloat(this.cashBalanceTarget.value);

    // Update income sources
    const ss = baseProfile.income_sources.find(s => s.type === 'social_security');
    if (ss) {
      ss.pia_annual = parseFloat(this.piaAnnualTarget.value);
      ss.claiming_age = parseInt(this.claimingAgeTarget.value, 10);
    }

    // Update household
    baseProfile.household.annual_expenses = parseFloat(this.annualExpensesTarget.value);
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
        body: JSON.stringify({ profile: profile })
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Server error:', errorText);
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const results = await response.json();
      console.log('Received results:', results);

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
