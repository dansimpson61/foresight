window.addEventListener('DOMContentLoaded', () => {
  // A Stimulus controller to manage the editable financial profile
  class ProfileController extends Stimulus.Controller {
    static targets = [
      "form",
      "annualExpenses",
      "traditionalBalance",
      "rothBalance",
      "taxableBalance",
      "piaAnnual"
    ]

    connect() {
      console.log("Profile controller connected");
      this.load();
    }

    toggleEditor() {
      this.formTarget.classList.toggle('hidden');
    }

    load() {
      const savedProfile = localStorage.getItem('simpleForesightProfile');
      if (savedProfile) {
        const profile = JSON.parse(savedProfile);
        // Populate the form with saved data
        this.annualExpensesTarget.value = profile.household.annual_expenses;
        this.traditionalBalanceTarget.value = profile.accounts.find(a => a.type === 'traditional').balance;
        this.rothBalanceTarget.value = profile.accounts.find(a => a.type === 'roth').balance;
        this.taxableBalanceTarget.value = profile.accounts.find(a => a.type === 'taxable').balance;
        this.piaAnnualTarget.value = profile.income_sources.find(s => s.type === 'social_security').pia_annual;
      }
    }

    save() {
      // Construct the profile object from the form
      const profile = this.buildProfileFromForm();

      // Save to localStorage
      localStorage.setItem('simpleForesightProfile', JSON.stringify(profile));

      // Re-run the simulation
      this.rerunSimulation(profile);
    }

    buildProfileFromForm() {
      // This is a simplified reconstruction. A real app would need more robust handling.
      // We start with the default profile to get all the non-editable fields.
      const baseProfile = JSON.parse(document.getElementById('default-profile-data').textContent);

      baseProfile.household.annual_expenses = parseInt(this.annualExpensesTarget.value, 10);
      baseProfile.accounts.find(a => a.type === 'traditional').balance = parseInt(this.traditionalBalanceTarget.value, 10);
      baseProfile.accounts.find(a => a.type === 'roth').balance = parseInt(this.rothBalanceTarget.value, 10);
      baseProfile.accounts.find(a => a.type === 'taxable').balance = parseInt(this.taxableBalanceTarget.value, 10);
      baseProfile.income_sources.find(s => s.type === 'social_security').pia_annual = parseInt(this.piaAnnualTarget.value, 10);

      return baseProfile;
    }

    async rerunSimulation(profile) {
      const response = await fetch('/run', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(profile)
      });

      const results = await response.json();

      // Dispatch an event with the new results
      const event = new CustomEvent('profile:updated', { detail: { results } });
      window.dispatchEvent(event);
    }
  }

  // Register the new controller
  // We assume the Stimulus application is already started by chart_controller.js
  if (window.Stimulus) {
    const application = window.Stimulus;
    application.register("profile", ProfileController);
  }
});