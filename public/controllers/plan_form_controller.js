import { Controller } from '../vendor/stimulus.js';
import debounce from 'https://cdn.jsdelivr.net/npm/lodash.debounce@4.0.8/+esm'

export default class extends Controller {
  static targets = [
    // Household
    'yourAge', 'yourAgeNumber',
    'spouseAge', 'spouseAgeNumber',
    'filingStatus', 'state',

    // Financial State
    'tradIRA', 'tradIRANumber',
    'rothIRA', 'rothIRANumber',
    'taxableBrokerage', 'taxableBrokerageNumber',
    'costBasis', 'costBasisNumber',
    'cashSavings', 'cashSavingsNumber',
    'emergencyFund', 'emergencyFundNumber',
    'otherAssets', 'liabilities',

    // Annual Income
    'yourIncome', 'yourSSFRA', 'yourSSClaimAge', 'yourPension',
    'spouseIncome', 'spouseSSFRA', 'spouseSSClaimAge', 'spousePension',

    // Spending & Withdrawals
    'annualExpenses', 'annualExpensesNumber',
    'withdrawal1', 'withdrawal2', 'withdrawal3', 'withdrawal4',

    // Assumptions
    'investmentGrowth', 'investmentGrowthNumber',
    'inflationRate', 'inflationRateNumber',
    'analysisHorizon', 'analysisHorizonNumber',

    // Strategy
    'strategySelector', 'strategyControls'
  ];

  connect() {
    this.runPlan = debounce(this.runPlan.bind(this), 500);
    
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
    
    this.initializeNumberInputs();
    this.runPlan();
  }

  initializeNumberInputs() {
    this.syncableTargets.forEach(pair => {
      pair.number.value = pair.slider.value;
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

  runPlan() {
    const parameters = this.buildParameters();
    fetch('/plan', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(parameters),
    })
      .then(response => response.json())
      .then(data => {
        this.results = data.data.results || {};
        // Temporarily disable selector population until strategies are dynamic
        // this.populateStrategySelector(); 
        this.updateResultsForSelectedStrategy();
      })
      .catch(error => {
        console.error('Error fetching or parsing plan data:', error);
        this.results = {};
      });
  }

  buildParameters() {
    const currentYear = new Date().getFullYear();
    const yourBirthYear = currentYear - parseInt(this.yourAgeTarget.value, 10);
    const spouseBirthYear = currentYear - parseInt(this.spouseAgeTarget.value, 10);
    const growthRate = parseFloat(this.investmentGrowthTarget.value) / 100;

    return {
      // 1. Household & Demographics
      members: [
        { name: "You", date_of_birth: `${yourBirthYear}-01-01` },
        { name: "Spouse", date_of_birth: `${spouseBirthYear}-01-01` }
      ],
      filing_status: this.filingStatusTargets.find(r => r.checked).value,
      state: this.stateTarget.value,
      analysis_horizon: parseInt(this.analysisHorizonTarget.value, 10),
      start_year: currentYear,

      // 2. Financial State
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
      emergency_fund_floor: parseInt(this.emergencyFundTarget.value, 10),
      other_assets: parseInt(this.otherAssetsTarget.value, 10),
      liabilities: parseInt(this.liabilitiesTarget.value, 10),

      // 3. Income Streams
      income_sources: [
        { type: "Salary", recipient: "You", annual_gross: parseInt(this.yourIncomeTarget.value, 10) },
        { type: "Salary", recipient: "Spouse", annual_gross: parseInt(this.spouseIncomeTarget.value, 10) },
        { type: "Pension", recipient: "You", annual_gross: parseInt(this.yourPensionTarget.value, 10) },
        { type: "Pension", recipient: "Spouse", annual_gross: parseInt(this.spousePensionTarget.value, 10) },
        { type: "SocialSecurity", recipient: "You", fra_benefit: parseInt(this.yourSSFRATarget.value, 10) * 12, claiming_age: parseInt(this.yourSSClaimAgeTarget.value, 10) },
        { type: "SocialSecurity", recipient: "Spouse", fra_benefit: parseInt(this.spouseSSFRATarget.value, 10) * 12, claiming_age: parseInt(this.spouseSSClaimAgeTarget.value, 10) }
      ],
      
      // 4. Spending Plan
      annual_expenses: parseInt(this.annualExpensesTarget.value, 10),
      
      // 5. Strategic Scenarios
      roth_conversion_strategy: {
        type: this.strategySelectorTarget.value,
        parameters: {} // Placeholder for strategy-specific controls
      },
      withdrawal_hierarchy: [
        this.withdrawal1Target.value,
        this.withdrawal2Target.value,
        this.withdrawal3Target.value,
        this.withdrawal4Target.value,
      ],

      // 6. Economic Assumptions
      inflation_rate: parseFloat(this.inflationRateTarget.value) / 100,
      growth_assumptions: {
        traditional_ira: growthRate,
        roth_ira: growthRate,
        taxable: growthRate,
        cash: 0.005 // Assuming a minimal growth for cash
      }
    };
  }

  // To be re-enabled when backend returns multiple strategies
  // populateStrategySelector() { ... }

  updateResultsForSelectedStrategy() {
    // The backend currently only returns one strategy based on the input
    // so we can just use the first (and only) result set.
    const strategyKey = Object.keys(this.results)[0];
    if (!strategyKey) return;

    const results = this.results[strategyKey] || {};
    const event = new CustomEvent('plan:results', { detail: { results } });
    document.dispatchEvent(event);
  }
}
