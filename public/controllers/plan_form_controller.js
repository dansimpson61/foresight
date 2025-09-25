import { Controller } from 'stimulus';

// A simple, joyful debounce implementation, as is our way.
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

export default class extends Controller {
  static targets = [
    'yourAge', 'yourAgeNumber', 'spouseAge', 'spouseAgeNumber', 'filingStatus', 'state',
    'tradIRA', 'tradIRANumber', 'rothIRA', 'rothIRANumber', 'taxableBrokerage', 'taxableBrokerageNumber',
    'costBasis', 'costBasisNumber', 'cashSavings', 'cashSavingsNumber', 'emergencyFund', 'emergencyFundNumber',
    'otherAssets', 'liabilities',
    'yourIncome', 'yourSSFRA', 'yourSSClaimAge', 'yourPension', 'spouseIncome', 'spouseSSFRA',
    'spouseSSClaimAge', 'spousePension',
    'annualExpenses', 'annualExpensesNumber',
    'withdrawal1', 'withdrawal2', 'withdrawal3', 'withdrawal4',
    'investmentGrowth', 'investmentGrowthNumber', 'inflationRate', 'inflationRateNumber',
    'analysisHorizon', 'analysisHorizonNumber',
    'strategySelector', 'strategyControls', 'yearRangeControls', 'bracketControls', 'amountControls',
    'startYear', 'endYear', 'bracketCeiling', 'conversionAmount',
    "errorDisplay"
  ];

  connect() {
    this.runPlan = debounce(this.runPlan.bind(this), 500);
    this.initializeSyncableTargets();
    this.initializeNumberInputs();
    this.handleStrategyChange();
    this.runPlan();
  }
  
  initializeSyncableTargets() {
     this.syncableTargets = [
      { slider: this.yourAgeTarget, number: this.yourAgeNumberTarget },
      { slider: this.spouseAgeTarget, number: this.spouseAgeNumberTarget },
      { slider: this.tradIRATarget, number: this.tradIRANumberTarget },
      { slider: this.rothIRATarget, number: this.rothIRANumberTarget },
      { slider: this.taxableBrokerageTarget, number: this.taxableBrokerageNumberTarget },
      { slider: this.costBasisTarget, number: this.costBasisNumberTarget },
      { slider: this.cashSavingsTarget, number: this.cashSavingsNumberTarget },
      { slider: this.emergencyFundTarget, number: this.emergencyFundNumberTarget },
      { slider: this.annualExpensesTarget, number: this.annualExpensesNumberTarget },
      { slider: this.investmentGrowthTarget, number: this.investmentGrowthNumberTarget },
      { slider: this.inflationRateTarget, number: this.inflationRateNumberTarget },
      { slider: this.analysisHorizonTarget, number: this.analysisHorizonNumberTarget },
    ];
  }

  initializeNumberInputs() {
    this.syncableTargets.forEach(pair => {
      if (pair.slider && pair.number) {
        pair.number.value = pair.slider.value;
      }
    });
  }

  sync(event) {
    const changedElement = event.target;
    const pair = this.syncableTargets.find(p => p.slider === changedElement || p.number === changedElement);
    
    if (pair) {
      if (changedElement.type === 'range') {
        pair.number.value = changedElement.value;
      } else {
        pair.slider.value = changedElement.value;
      }
    }
    this.runPlan();
  }

  async runPlan() {
    this.clearError();
    const parameters = this.buildParameters();
    const wrappedPayload = {
      metadata: {
        sender: 'Foresight::UI',
        intended_receiver: 'Foresight::API',
        timestamp: new Date().toISOString()
      },
      payload: parameters
    };
    
    // Log the payload to the console for verification
    console.log("Sending payload:", JSON.stringify(wrappedPayload, null, 2));

    try {
      const response = await fetch('/plan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(wrappedPayload),
      });

      const data = await response.json();

      if (response.ok) {
        this.fullResults = data.payload.data; // Unwrap the payload
        this.dispatchResults();
      } else {
        this.showError(data.payload);
      }
    } catch (error) {
      this.showError({
        communication_step: 'Network',
        message: 'Could not connect to the server. Please check your network connection.'
      });
    }
  }

  showError(errorData) {
    const title = `Error: Breakdown in '${errorData.communication_step}'`;
    const details = errorData.message;

    const errorTitleElement = this.errorDisplayTarget.querySelector('h4');
    const errorBodyElement = this.errorDisplayTarget.querySelector('p');

    errorTitleElement.textContent = title;
    errorBodyElement.textContent = details;
    this.errorDisplayTarget.hidden = false;
  }

  clearError() {
    this.errorDisplayTarget.hidden = true;
    this.errorDisplayTarget.querySelector('h4').textContent = '';
    this.errorDisplayTarget.querySelector('p').textContent = '';
  }

  dispatchResults() {
    if (!this.fullResults) return;

    const activeStrategyKey = this.strategySelectorTarget.value;
    const simulationResults = this.fullResults.results[activeStrategyKey];
    
    if (simulationResults) {
      const event = new CustomEvent('plan:results', { detail: { results: simulationResults } });
      document.dispatchEvent(event);
    } else {
      this.showError({
        communication_step: 'Frontend Data Handling',
        message: `Could not find results for the selected strategy ('${activeStrategyKey}') in the data from the server.`
      });
    }
  }
  
  handleStrategyChange() {
    const strategy = this.strategySelectorTarget.value;

    this.yearRangeControlsTarget.hidden = !strategy.includes('by_year');
    this.bracketControlsTarget.hidden = !strategy.includes('bracket');
    this.amountControlsTarget.hidden = !strategy.includes('amount');

    this.dispatchResults();
  }

  buildParameters() {
    const currentYear = new Date().getFullYear();
    const yourBirthYear = currentYear - parseInt(this.yourAgeTarget.value, 10);
    const spouseBirthYear = currentYear - parseInt(this.spouseAgeTarget.value, 10);
    const growthRate = parseFloat(this.investmentGrowthTarget.value) / 100;

    const strategies = [
      { key: 'do_nothing', params: {} },
      { key: 'fill_to_top_of_bracket', params: { ceiling: parseInt(this.bracketCeilingTarget.value, 10) || 0 } },
      { key: 'fill_bracket_no_ss', params: { ceiling: parseInt(this.bracketCeilingTarget.value, 10) || 0 } },
      { key: 'fill_bracket_by_year_no_ss', params: {
          ceiling: parseInt(this.bracketCeilingTarget.value, 10) || 0,
          start_year: parseInt(this.startYearTarget.value, 10) || currentYear,
          end_year: parseInt(this.endYearTarget.value, 10) || currentYear + 1
        }
      }
    ];

    return {
      members: [
        { name: "You", date_of_birth: `${yourBirthYear}-01-01` },
        { name: "Spouse", date_of_birth: `${spouseBirthYear}-01-01` }
      ],
      accounts: [
        { type: "TraditionalIRA", owner: "You", balance: parseInt(this.tradIRATarget.value, 10) },
        { type: "RothIRA", owner: "You", balance: parseInt(this.rothIRATarget.value, 10) },
        { 
          type: "TaxableBrokerage", 
          owners: ["You", "Spouse"], 
          balance: parseInt(this.taxableBrokerageTarget.value, 10), 
          cost_basis_fraction: parseFloat(this.costBasisTarget.value) / 100 
        },
        { type: "Cash", balance: parseInt(this.cashSavingsTarget.value, 10) }
      ],
      income_sources: [
        { type: "Salary", recipient: "You", annual_gross: parseInt(this.yourIncomeTarget.value, 10) },
        { type: "Salary", recipient: "Spouse", annual_gross: parseInt(this.spouseIncomeTarget.value, 10) },
        { type: "Pension", recipient: "You", annual_gross: parseInt(this.yourPensionTarget.value, 10) },
        { type: "Pension", recipient: "Spouse", annual_gross: parseInt(this.spousePensionTarget.value, 10) },
        { 
          type: "SocialSecurityBenefit", 
          recipient: "You", 
          pia_annual: parseInt(this.yourSSFRATarget.value, 10) * 12,
          claiming_age: parseInt(this.yourSSClaimAgeTarget.value, 10)
        },
        { 
          type: "SocialSecurityBenefit", 
          recipient: "Spouse", 
          pia_annual: parseInt(this.spouseSSFRATarget.value, 10) * 12,
          claiming_age: parseInt(this.spouseSSClaimAgeTarget.value, 10)
        }
      ],
      annual_expenses: parseInt(this.annualExpensesTarget.value, 10),
      emergency_fund_floor: parseInt(this.emergencyFundTarget.value, 10),
      filing_status: this.filingStatusTargets.find(r => r.checked).value,
      state: this.stateTarget.value,
      years: parseInt(this.analysisHorizonTarget.value, 10),
      start_year: currentYear,
      inflation_rate: parseFloat(this.inflationRateTarget.value) / 100,
      growth_assumptions: {
        traditional_ira: growthRate,
        roth_ira: growthRate,
        taxable: growthRate,
        cash: 0.005
      },
      strategies: strategies,
      withdrawal_hierarchy: [
        this.withdrawal1Target.value, this.withdrawal2Target.value,
        this.withdrawal3Target.value, this.withdrawal4Target.value
      ]
    };
  }
}
