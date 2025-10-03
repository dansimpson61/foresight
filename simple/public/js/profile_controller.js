// A Stimulus controller to manage the editable financial profile
// No localStorage - embracing ephemerality and honesty
// A Stimulus controller to manage the editable financial profile
class ProfileController extends Stimulus.Controller {
  static targets = [
    "form",
    "memberName",
    "dateOfBirth",
    "accountBalance",
    "accountCostBasis",
    "piaAnnual",
    "claimingAge",
    "annualExpenses",
    "filingStatus",
    "saveButton"
  ]

  toggleEditor() {
    this.formTarget.classList.toggle('hidden');
  }

  save() {
    const profile = this.buildProfileFromForm();
    this.rerunSimulation(profile);
    this.formTarget.classList.add('hidden');
  }

  buildProfileFromForm() {
    const baseProfile = JSON.parse(document.getElementById('default-profile-data').textContent);

    // Update members from the form using their data-member-index
    this.memberNameTargets.forEach(input => {
      const index = parseInt(input.dataset.memberIndex, 10);
      baseProfile.members[index].name = input.value;
    });
    this.dateOfBirthTargets.forEach(input => {
      const index = parseInt(input.dataset.memberIndex, 10);
      baseProfile.members[index].date_of_birth = input.value;
    });

    // Update accounts from the form using their data-account-index
    this.accountBalanceTargets.forEach(input => {
      const index = parseInt(input.dataset.accountIndex, 10);
      baseProfile.accounts[index].balance = parseFloat(input.value);
    });
    this.accountCostBasisTargets.forEach(input => {
      const index = parseInt(input.dataset.accountIndex, 10);
      if ('cost_basis_fraction' in baseProfile.accounts[index]) {
        baseProfile.accounts[index].cost_basis_fraction = parseFloat(input.value);
      }
    });

    // Update income sources from the form using their data-source-index
    this.piaAnnualTargets.forEach(input => {
      const index = parseInt(input.dataset.sourceIndex, 10);
      baseProfile.income_sources[index].pia_annual = parseFloat(input.value);
    });
    this.claimingAgeTargets.forEach(input => {
      const index = parseInt(input.dataset.sourceIndex, 10);
      baseProfile.income_sources[index].claiming_age = parseInt(input.value, 10);
    });

    // Update household info
    baseProfile.household.annual_expenses = parseFloat(this.annualExpensesTarget.value);
    baseProfile.household.filing_status = this.filingStatusTarget.value;

    return baseProfile;
  }

  async rerunSimulation(profile) {
    const button = this.saveButtonTarget;
    const originalText = button.textContent;

    // Provide joyful feedback to the user
    button.disabled = true;
    button.textContent = 'Calculating...';

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
    } finally {
      // Always restore the button to its original state
      button.disabled = false;
      button.textContent = originalText;
    }
  }
}
