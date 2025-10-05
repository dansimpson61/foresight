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
    application.register("profile", ProfileController);
    application.register("simulation", SimulationController);
    application.register("results", ResultsController);
    application.register("net-worth-chart", NetWorthChartController);
    application.register("accordion", AccordionController);
    application.register("flows", FlowsController);
    console.log('[Foresight] Stimulus started and controllers registered');
    // Visual status badge for quick smoke checks
    var badge = document.createElement('div');
    badge.textContent = 'Controllers: started';
    badge.style.position = 'fixed';
    badge.style.bottom = '8px';
    badge.style.left = '8px';
    badge.style.padding = '4px 8px';
    badge.style.background = '#16a34a';
    badge.style.color = 'white';
    badge.style.fontSize = '12px';
    badge.style.borderRadius = '4px';
    badge.style.zIndex = '9999';
    badge.style.opacity = '0.85';
    document.body.appendChild(badge);
  } catch (e) {
    console.error('[Foresight] Failed to register controllers', e);
  }
})();