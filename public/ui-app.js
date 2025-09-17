import { Application } from './vendor/stimulus.js';
import ChartsController from './controllers/charts_controller.js';
import PlanFormController from './controllers/plan_form_controller.js';
import ResultsTableController from './controllers/results_table_controller.js';
import SummaryController from './controllers/summary_controller.js';
import TaxBracketSliderController from './controllers/tax_bracket_slider_controller.js';

const application = Application.start();
application.register('charts', ChartsController);
application.register('plan-form', PlanFormController);
application.register('results-table', ResultsTableController);
application.register('summary', SummaryController);
application.register('tax-bracket-slider', TaxBracketSliderController);
