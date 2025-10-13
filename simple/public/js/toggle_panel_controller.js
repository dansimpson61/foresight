// A lightweight edge-anchored toggle panel with CSS Grid natural flow
// Supports recursive nesting - panel content areas are grid containers too!
// Usage (basic):
// <div data-controller="toggle-panel" data-toggle-panel-position-value="left">
//   ...your content...
// </div>
// Usage (nested):
// <div data-controller="toggle-panel" ...>
//   <div data-controller="toggle-panel" ...>Nested panel</div>
//   <div>Main content flows naturally</div>
// </div>
// Optional values:
//   data-toggle-panel-collapsed-size-value="2.5rem"
//   data-toggle-panel-expanded-size-value="min(360px, 85vw)"
//   data-toggle-panel-label-value="Tools"
//   data-toggle-panel-icon-value="☰"
//   data-toggle-panel-icons-only-value="true"
class TogglePanelController extends Stimulus.Controller {
  static values = {
    position: { type: String, default: 'left' },
    collapsedSize: String,
    expandedSize: String,
    label: { type: String, default: 'Panel' },
    nested: { type: Boolean, default: false },
    offset: String,
    icon: String,
    iconsOnly: { type: Boolean, default: false }
  }

  static targets = ["content", "handle"]

  connect() {
    // Wrap inner content if not already wrapped, but DO NOT wrap nested toggle panels
    if (!this.hasContentTarget) {
      const wrapper = document.createElement('div');
      wrapper.className = 'toggle-panel__content';
      wrapper.setAttribute('data-toggle-panel-target', 'content');
      // snapshot children first (live list would change during moves)
      const kids = Array.from(this.element.childNodes);
      kids.forEach((node) => {
        // Only move element/text nodes that are not nested toggle panels
        if (node.nodeType === Node.ELEMENT_NODE) {
          const el = node;
          const dc = el.getAttribute && el.getAttribute('data-controller');
          const isTP = dc && dc.split(/\s+/).includes('toggle-panel');
          const isNested = el.getAttribute && el.getAttribute('data-toggle-panel-nested-value') === 'true';
          if (isTP && isNested) return; // leave nested panels at root level
        }
        // Move everything else into content wrapper
        wrapper.appendChild(node);
      });
      this.element.appendChild(wrapper);
    }

    // Create a handle if not present (still helpful for keyboard users)
    if (!this.hasHandleTarget) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'toggle-panel__handle';
      btn.setAttribute('aria-label', `Toggle ${this.labelValue}`);
      btn.setAttribute('data-toggle-panel-target', 'handle');
      btn.addEventListener('click', (e) => { e.stopPropagation(); this.toggle(); });
      this.element.appendChild(btn);
    }

    // Ensure a visible label in the upper-left for context (with optional icon)
    if (!this._labelEl) {
      const label = document.createElement('div');
      label.className = 'toggle-panel__label';
      // decorative; doesn’t intercept clicks
      label.setAttribute('aria-hidden', 'true');
      const iconSpan = document.createElement('span');
      iconSpan.className = 'toggle-panel__icon';
      const textSpan = document.createElement('span');
      textSpan.className = 'toggle-panel__text';
      const iconString = this.hasIconValue ? this.iconValue : (this._isVertical() ? '☰' : '');
      if (iconString) iconSpan.textContent = iconString;
      textSpan.textContent = this.labelValue;
      label.appendChild(iconSpan);
      label.appendChild(textSpan);
      this._labelEl = label;
      this.element.appendChild(label);
    }

    // Initialize positioning
    this.element.classList.add('toggle-panel');
    this.element.setAttribute('role', 'region');
    this.element.setAttribute('aria-label', this.labelValue);
    
    // Positioning: relative for grid flow (both top-level and nested)
    this.element.style.position = 'relative';

    // Orientation class for CSS sizing
    const vertical = this._isVertical();
    this.element.classList.toggle('is-vertical', vertical);
    this.element.classList.toggle('is-horizontal', !vertical);

    // Icons-only default for vertical panels unless explicitly overridden
    const iconsOnly = this.hasIconsOnlyValue ? this.iconsOnlyValue : vertical;
    this.element.classList.toggle('is-icons-only', !!iconsOnly);

    // Apply instance size variables if provided (CSS controls default behavior)
    if (this.hasCollapsedSizeValue) {
      this.element.style.setProperty(vertical ? '--tp-collapsed-size-v' : '--tp-collapsed-size-h', this.collapsedSizeValue);
    }
    if (this.hasExpandedSizeValue) {
      this.element.style.setProperty(vertical ? '--tp-expanded-size-v' : '--tp-expanded-size-h', this.expandedSizeValue);
    }

    // Default: hover opens via CSS; clicking anywhere toggles sticky open/closed
    this.sticky = false;
    this._updateA11y();
    this._updateHandleIcon();

    // Click anywhere in the panel toggles sticky
    this._onPanelClick = () => this.toggle();
    this.element.addEventListener('click', this._onPanelClick);
  }

  disconnect() {
    if (this._onPanelClick) this.element.removeEventListener('click', this._onPanelClick);
  }

  toggle() {
    this.sticky = !this.sticky;
    this.element.classList.toggle('is-sticky', this.sticky);
    this._updateA11y();
    this._updateHandleIcon();
  }

  // --- Internals ---
  _updateA11y() {
    if (this.hasHandleTarget) this.handleTarget.setAttribute('aria-expanded', String(this.sticky));
  }

  _updateHandleIcon() {
    const pos = this.positionValue;
    let icon = '≡';
    if (pos === 'left') icon = this.sticky ? '⟨' : '⟩';
    else if (pos === 'right') icon = this.sticky ? '⟩' : '⟨';
    else if (pos === 'top') icon = this.sticky ? '⌃' : '⌄';
    else icon = this.sticky ? '⌄' : '⌃';
    if (this.hasHandleTarget) this.handleTarget.textContent = icon;
  }

  _expandedSize() {
    const cs = getComputedStyle(this.element);
    const vertical = (this.positionValue === 'left' || this.positionValue === 'right');
    const varName = vertical ? '--tp-expanded-size-v' : '--tp-expanded-size-h';
    let val = cs.getPropertyValue(varName).trim();
    if (!val) {
      val = vertical ? (this.hasExpandedSizeValue ? this.expandedSizeValue : 'min(360px, 85vw)')
                     : (this.hasExpandedSizeValue ? this.expandedSizeValue : 'min(40vh, 480px)');
    }
    return val || '0px';
  }

  _collapsedSize() {
    const cs = getComputedStyle(this.element);
    const vertical = (this.positionValue === 'left' || this.positionValue === 'right');
    const varName = vertical ? '--tp-collapsed-size-v' : '--tp-collapsed-size-h';
    let val = cs.getPropertyValue(varName).trim();
    if (!val) {
      val = vertical ? (this.hasCollapsedSizeValue ? this.collapsedSizeValue : '2.75rem')
                     : (this.hasCollapsedSizeValue ? this.collapsedSizeValue : '2.25rem');
    }
    return val || '0px';
  }

  _isVertical() {
    return this.positionValue === 'left' || this.positionValue === 'right';
  }
}

// expose globally for application.js registration
window.TogglePanelController = TogglePanelController;
