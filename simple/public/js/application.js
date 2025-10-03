window.addEventListener('DOMContentLoaded', () => {
  const application = Stimulus.Application.start();

  // Register all controllers
  application.register("chart", ChartController);
  application.register("profile", ProfileController);
  application.register("simulation", SimulationController);
  application.register("results", ResultsController);
  application.register("net-worth-chart", NetWorthChartController);
  application.register("accordion", AccordionController);
});