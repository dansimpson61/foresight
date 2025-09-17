import { Controller } from '../vendor/stimulus.js';
import debounce from 'https://cdn.jsdelivr.net/npm/lodash.debounce@4.0.8/+esm'

export default class extends Controller {
  static targets = [
    'yourAge', 'yourAgeNumber',
    'spouseAge', 'spouseAgeNumber',
    'filingStatus', 'state',
    'tradIRA', 'tradIRANumber',
    'rothIRA', 'rothIRANumber',
    'taxableBrokerage', 'taxableBrokerageNumber',
    'annualIncome', 'annualIncomeNumber',
    'investmentGrowth', 'investmentGrowthNumber',
    'inflationRate', 'inflationRateNumber',
    'analysisHorizon', 'analysisHorizonNumber',
    'strategySelector'
  ];

  connect() {
    this.runPlan = debounce(this.runPlan.bind(this), 500);
    
    this.syncableTargets = [
      { slider: this.yourAgeTarget, number: this.yourAgeNumberTarget },
      { slider: this.spouseAgeTarget, number: this.spouseAgeNumberTarget },
      { slider: this.tradIRATarget, number: this.tradIRANumberTarget },
      { slider: this.rothIRATarget, number: this.rothIRANumberTarget },
      { slider: this.taxableBrokerageTarget, number: this.taxableBrokerageNumberTarget },
      { slider: this.annualIncomeTarget, number: this.annualIncomeNumberTarget },
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
        this.populateStrategySelector();
        this.updateResults();
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
      "members": [
        { "name": "You", "date_of_birth": `${yourBirthYear}-01-01` },
        { "name": "Spouse", "date_of_birth": `${spouseBirthYear}-01-01` }
      ],
      "accounts": [
        { "type": "TraditionalIRA", "owner": "You", "balance": parseInt(this.tradIRATarget.value, 10) },
        { "type": "RothIRA", "owner": "You", "balance": parseInt(this.rothIRATarget.value, 10) },
        { "type": "TaxableBrokerage", "owners": ["You", "Spouse"], "balance": parseInt(this.taxableBrokerageTarget.value, 10), "cost_basis_fraction": 0.7 }
      ],
      "income_sources": [
        { 
          "type": "Pension", 
          "recipient": "You", 
          "start_year": currentYear,
          "annual_gross": parseInt(this.annualIncomeTarget.value, 10) 
        }
      ],
      "target_spending_after_tax": 80000,
      "desired_tax_bracket_ceiling": 94300,
      "start_year": currentYear,
      "years": parseInt(this.analysisHorizonTarget.value, 10),
      "inflation_rate": parseFloat(this.inflationRateTarget.value) / 100,
      "growth_assumptions": {
        "traditional_ira": growthRate,
        "roth_ira": growthRate,
        "taxable": growthRate
      }
    };
  }

  populateStrategySelector() {
    if (!this.results || Object.keys(this.results).length === 0) return;
    
    const currentSelection = this.strategySelectorTarget.value;
    const strategyKeys = Object.keys(this.results);
    
    const options = Array.from(this.strategySelectorTarget.options).map(o => o.value);
    if (JSON.stringify(options) === JSON.stringify(strategyKeys)) return;
    
    this.strategySelectorTarget.innerHTML = '';
    strategyKeys.forEach(key => {
      const option = document.createElement('option');
      option.value = key;
      option.textContent = key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
      this.strategySelectorTarget.appendChild(option);
    });

    if (strategyKeys.includes(currentSelection)) {
      this.strategySelectorTarget.value = currentSelection;
    }
  }

  updateResults() {
    const selectedStrategy = this.strategySelectorTarget.value;
    const results = this.results[selectedStrategy] || {};
    const event = new CustomEvent('plan:results', { detail: { results } });
    document.dispatchEvent(event);
  }
}
