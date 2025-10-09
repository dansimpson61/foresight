// sp_panel_controller.js
// A tiny, elegant Stimulus controller for the "slim pickins" panel.
// Responsibilities:
// 1. Toggle CSS classes based on hover and click.
// 2. Keep ARIA attributes in sync for accessibility.
// That's it. CSS does all the heavy lifting for layout and animation.

class SpPanelController extends Stimulus.Controller {
  connect() {
    this.sticky = false;
    this.element.addEventListener('mouseenter', () => this.expand());
    this.element.addEventListener('mouseleave', () => this.collapse());
    this._updateA11y();
  }

  // This action is triggered by clicking the panel's label/button.
  // It toggles the "sticky" state.
  toggle() {
    this.sticky = !this.sticky;
    this.element.classList.toggle('is-sticky', this.sticky);

    // If the panel was just made sticky, ensure it's expanded.
    if (this.sticky) {
      this.expand();
    }
    this._updateA11y();
  }

  // Expands the panel, usually on mouseenter.
  expand() {
    this.element.classList.add('is-expanded');
    this._updateA11y();
  }

  // Collapses the panel, usually on mouseleave, but only if not sticky.
  collapse() {
    if (!this.sticky) {
      this.element.classList.remove('is-expanded');
      this._updateA11y();
    }
  }

  // Private helper to keep accessibility attributes current.
  _updateA11y() {
    const isExpanded = this.element.classList.contains('is-expanded');
    const button = this.element.querySelector('.sp-panel__label');
    if (button) {
      button.setAttribute('aria-expanded', isExpanded);
    }
  }
}

// Expose the controller globally so application.js can register it.
window.SpPanelController = SpPanelController;