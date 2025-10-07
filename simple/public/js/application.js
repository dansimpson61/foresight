(function bootstrap() {
  if (typeof Stimulus === 'undefined' || !Stimulus.Application) {
    // If Stimulus hasn't loaded yet, retry shortly
    return setTimeout(bootstrap, 10);
  }

  // Prevent double-start
  if (window.__stimulusAppStarted) return;
  window.__stimulusAppStarted = true;

  const application = Stimulus.Application.start();

  try {
    // Register all controllers
  application.register("chart", ChartController);
  application.register("viz", VizController);
    application.register("profile", ProfileController);
    application.register("simulation", SimulationController);
    application.register("results", ResultsController);
    application.register("net-worth-chart", NetWorthChartController);
    application.register("accordion", AccordionController);
    application.register("flows", FlowsController);
  console.log('[Foresight] Stimulus started and controllers registered');
  } catch (e) {
    console.error('[Foresight] Failed to register controllers', e);
  }
})();