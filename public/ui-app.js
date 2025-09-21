import { Application } from 'stimulus';

// Import and register all your controllers from the import map
import ChartsController from 'charts';
import PlanFormController from 'plan-form';
import ResultsTableController from 'results-table';
import SummaryController from 'summary';
import TaxBracketSliderController from 'tax-bracket-slider';

const application = Application.start();
application.register('charts', ChartsController);
application.register('plan-form', PlanFormController);
application.register('results-table', ResultsTableController);
application.register('summary', SummaryController);
application.register('tax-bracket-slider', TaxBracketSliderController);
// Note: Removed non-existent 'income-chart' controller to avoid module resolution errors
