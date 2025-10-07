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
    "accountOwner",
    "piaAnnual",
    "claimingAge",
    "incomeRecipient",
    "annualExpenses",
    "householdState",
    "filingStatus",
    "withdrawalHierarchy",
    "emergencyFundFloor",
    "saveButton"
  ]

  connect() {
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
    const profile = this.buildProfileFromForm();
    this.rerunSimulation(profile);
    this.formTarget.classList.add('hidden');
  }

  async resetDefaults() {
    try {
      if (window.FSUtils && FSUtils.fetchJson) { await FSUtils.fetchJson('/reset_defaults', {}); }
      else { const res = await fetch('/reset_defaults', { method: 'POST' }); if (!res.ok) throw new Error('Failed to reset defaults'); }
      // Reload page to pick up defaults
      window.location.reload();
    } catch (e) {
      alert('Could not reset defaults.');
    }
  }

  async saveAsDefaults() {
    try {
      const profile = this.buildProfileFromForm();
      const payload = { profile, strategy: 'fill_to_bracket', strategy_params: { ceiling: 94300 } };
      if (window.FSUtils && FSUtils.fetchJson) {
        await FSUtils.fetchJson('/save_defaults', payload);
      } else {
        const res = await fetch('/save_defaults', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
        if (!res.ok) throw new Error('Failed to save defaults');
      }
      alert('Defaults saved for this server.');
    } catch (e) {
      alert('Could not save defaults.');
    }
  }

  async clearServerDefaults() {
    try {
      if (window.FSUtils && FSUtils.fetchJson) { await FSUtils.fetchJson('/clear_defaults', {}); }
      else { const res = await fetch('/clear_defaults', { method: 'POST' }); if (!res.ok) throw new Error('Failed to clear server defaults'); }
      window.location.reload();
    } catch (e) {
      alert('Could not clear server defaults.');
    }
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
    this.accountOwnerTargets.forEach(select => {
      const index = parseInt(select.dataset.accountIndex, 10);
      baseProfile.accounts[index].owner = select.value;
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
    this.incomeRecipientTargets.forEach(select => {
      const index = parseInt(select.dataset.sourceIndex, 10);
      baseProfile.income_sources[index].recipient = select.value;
    });

    // Update household info
    baseProfile.household.annual_expenses = parseFloat(this.annualExpensesTarget.value);
    if (this.hasHouseholdStateTarget) baseProfile.household.state = this.householdStateTarget.value;
    baseProfile.household.filing_status = this.filingStatusTarget.value;
    if (this.hasEmergencyFundFloorTarget) baseProfile.household.emergency_fund_floor = parseFloat(this.emergencyFundFloorTarget.value);
    if (this.hasWithdrawalHierarchyTarget) {
      const raw = this.withdrawalHierarchyTarget.value || '';
      baseProfile.household.withdrawal_hierarchy = raw.split(',').map(s => s.trim()).filter(Boolean).map(s => s.replace(/^:/, ''));
    }

    return baseProfile;
  }

  async rerunSimulation(profile) {
    const button = this.saveButtonTarget;
    const originalText = button.textContent;

    // Provide joyful feedback to the user
    button.disabled = true;
    button.textContent = 'Calculating...';

    try {
      const results = (window.FSUtils && FSUtils.fetchJson)
        ? await FSUtils.fetchJson('/run', { profile })
        : await (async () => { const r = await fetch('/run', { method:'POST', headers: { 'Content-Type':'application/json','Accept':'application/json' }, body: JSON.stringify({ profile }) }); if (!r.ok) { const t = await r.text(); console.error('Server error:', t); throw new Error(`HTTP error! status: ${r.status}`);} return r.json(); })();
      console.log('Received results:', results);

      // Dispatch event to update all visualizations
      const event = new CustomEvent('profile:updated', { 
        detail: { results, profile } 
      });
      window.dispatchEvent(event);
      // No client persistence; keep state server-side only
      
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
