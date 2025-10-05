// Visualization controller: lets users choose which strategy to visualize
class VizController extends Stimulus.Controller {
  static targets = ["badge", "radio"]

  connect() {
    this.updateBadge(this.current());
  }

  current() {
    const checked = this.radioTargets.find(r => r.checked);
    return checked ? checked.value : 'fill_to_bracket';
  }

  choose() {
    const strategy = this.current();
    this.updateBadge(strategy);
    const evt = new CustomEvent('visualization:changed', { detail: { strategy } });
    window.dispatchEvent(evt);
  }

  updateBadge(strategy) {
    if (!this.hasBadgeTarget) return;
    this.badgeTarget.textContent = strategy;
  }
}
