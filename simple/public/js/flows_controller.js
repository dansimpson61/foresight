// Minimal Stimulus controller to toggle the flows panel visibility
class FlowsController extends Stimulus.Controller {
  static targets = ["panel"]

  connect() {
    // nothing else for now
  }

  toggle() {
    if (!this.hasPanelTarget) return;
    this.panelTarget.classList.toggle('hidden');
  }
}
