// A Stimulus controller to manage the results display cards
// Listens for profile/simulation updates and refreshes the metrics
class ResultsController extends Stimulus.Controller {
  static targets = [
    "doNothingTaxes",
    "doNothingNetWorth", 
    "doNothingIncome",
    "doNothingExpenses",
    "fillBracketTaxes",
    "fillBracketNetWorth",
    "fillBracketIncome",
    "fillBracketExpenses"
  ]

  connect() {
    // Listen for updates from profile or simulation changes
    this.updateResults = this.updateResults.bind(this);
    window.addEventListener('profile:updated', this.updateResults);
    window.addEventListener('simulation:updated', this.updateResults);
  }

  disconnect() {
    window.removeEventListener('profile:updated', this.updateResults);
    window.removeEventListener('simulation:updated', this.updateResults);
  }

  updateResults(event) {
    const results = event.detail.results;
    
    // Update Do Nothing strategy metrics
    const doNothing = results.do_nothing_results;
    this.doNothingTaxesTarget.textContent = this.formatCurrency(doNothing.aggregate.cumulative_taxes);
    this.doNothingNetWorthTarget.textContent = this.formatCurrency(doNothing.aggregate.ending_net_worth);
    this.doNothingIncomeTarget.textContent = this.formatCurrency(doNothing.aggregate.total_gross_income);
    this.doNothingExpensesTarget.textContent = this.formatCurrency(doNothing.aggregate.total_expenses);

    // Update Fill to Bracket strategy metrics
    const fillBracket = results.fill_bracket_results;
    this.fillBracketTaxesTarget.textContent = this.formatCurrency(fillBracket.aggregate.cumulative_taxes);
    this.fillBracketNetWorthTarget.textContent = this.formatCurrency(fillBracket.aggregate.ending_net_worth);
    this.fillBracketIncomeTarget.textContent = this.formatCurrency(fillBracket.aggregate.total_gross_income);
    this.fillBracketExpensesTarget.textContent = this.formatCurrency(fillBracket.aggregate.total_expenses);
  }

  formatCurrency(number) {
    return new Intl.NumberFormat('en-US', { 
      style: 'currency', 
      currency: 'USD', 
      minimumFractionDigits: 0, 
      maximumFractionDigits: 0 
    }).format(number);
  }
}