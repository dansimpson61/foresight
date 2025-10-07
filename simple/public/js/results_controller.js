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
    this.doNothingTaxesTarget.textContent = (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(doNothing.aggregate.cumulative_taxes) : doNothing.aggregate.cumulative_taxes;
    this.doNothingNetWorthTarget.textContent = (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(doNothing.aggregate.ending_net_worth) : doNothing.aggregate.ending_net_worth;
    this.doNothingIncomeTarget.textContent = (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(doNothing.aggregate.total_gross_income) : doNothing.aggregate.total_gross_income;
    this.doNothingExpensesTarget.textContent = (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(doNothing.aggregate.total_expenses) : doNothing.aggregate.total_expenses;

    // Update Fill to Bracket strategy metrics
    const fillBracket = results.fill_bracket_results;
    this.fillBracketTaxesTarget.textContent = (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(fillBracket.aggregate.cumulative_taxes) : fillBracket.aggregate.cumulative_taxes;
    this.fillBracketNetWorthTarget.textContent = (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(fillBracket.aggregate.ending_net_worth) : fillBracket.aggregate.ending_net_worth;
    this.fillBracketIncomeTarget.textContent = (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(fillBracket.aggregate.total_gross_income) : fillBracket.aggregate.total_gross_income;
    this.fillBracketExpensesTarget.textContent = (FSUtils && FSUtils.formatCurrency) ? FSUtils.formatCurrency(fillBracket.aggregate.total_expenses) : fillBracket.aggregate.total_expenses;
  }
}