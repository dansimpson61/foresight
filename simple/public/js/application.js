window.addEventListener('DOMContentLoaded', () => {
  const application = Stimulus.Application.start();

  // Register all controllers
  application.register("chart", ChartController);
  application.register("profile", ProfileController);
  application.register("simulation", SimulationController);
});