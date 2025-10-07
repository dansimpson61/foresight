// Minimal Stimulus controller to toggle the flows panel visibility
class FlowsController extends Stimulus.Controller {
  static targets = ["panel"]

  toggle(event) {
    if (!this.hasPanelTarget) return;
    if (window.FSUtils && FSUtils.toggleExpanded) {
      FSUtils.toggleExpanded(this.panelTarget, event && event.currentTarget);
    } else {
      this.panelTarget.classList.toggle('hidden');
      if (event && event.currentTarget) {
        const expanded = !this.panelTarget.classList.contains('hidden');
        event.currentTarget.setAttribute('aria-expanded', String(expanded));
      }
    }
  }
}
