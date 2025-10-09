// A lightweight edge-anchored toggle panel
// Usage (left panel with defaults):
// <div data-controller="toggle-panel" data-toggle-panel-position-value="left">
//   ...your content...
// </div>
// Optional values:
//   data-toggle-panel-collapsed-size-value="2.5rem"
//   data-toggle-panel-expanded-size-value="min(360px, 85vw)"
//   data-toggle-panel-label-value="Tools"
class TogglePanelController extends Stimulus.Controller {
  static values = {
    position: { type: String, default: 'left' },
    collapsedSize: String,
    expandedSize: String,
    label: { type: String, default: 'Panel' },
    nested: { type: Boolean, default: false },
    pushSelector: String,
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
    // Positioning: viewport-fixed by default; absolute inside parent when nested
    this.element.style.position = this.nestedValue ? 'absolute' : 'fixed';
    this._applyAnchors();

    // Orientation class for CSS sizing
  const vertical = this._isVertical();
  this.element.classList.toggle('is-vertical', vertical);
  this.element.classList.toggle('is-horizontal', !vertical);

  // Icons-only default for vertical panels unless explicitly overridden
  const iconsOnly = this.hasIconsOnlyValue ? this.iconsOnlyValue : vertical;
  this.element.classList.toggle('is-icons-only', !!iconsOnly);

    // If nested, make sure parent is positioned for absolute anchoring
    if (this.nestedValue) {
      const parent = this.element.parentElement;
      if (parent) {
        const cs = window.getComputedStyle(parent);
        if (cs.position === 'static') parent.style.position = 'relative';
      }
    }

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

    // Hover handling to apply offsets while hovered (when not sticky)
    this._onEnter = () => { if (!this.sticky) { this._applyOffset(true); this._updateNestedPositions(); } };
    this._onLeave = () => { if (!this.sticky) { this._applyOffset(false); this._updateNestedPositions(); } };
    this.element.addEventListener('mouseenter', this._onEnter);
    this.element.addEventListener('mouseleave', this._onLeave);

    // Establish baseline layout for nested groups so collapsed bars don't cover content
    this._applyOffset(false);
    this._updateNestedPositions();
  }

  disconnect() {
    if (this._onPanelClick) this.element.removeEventListener('click', this._onPanelClick);
    if (this._onEnter) this.element.removeEventListener('mouseenter', this._onEnter);
    if (this._onLeave) this.element.removeEventListener('mouseleave', this._onLeave);
    // Remove any offsets we applied
    this._applyOffset(false);
  }

  toggle() {
    this.sticky = !this.sticky;
    this.element.classList.toggle('is-sticky', this.sticky);
    this._updateA11y();
    this._updateHandleIcon();
    this._applyOffset(this.sticky);
    this._updateNestedPositions();
  }

  // --- Internals ---
  _applyAnchors() {
    const s = this.element.style;
    s.top = s.right = s.bottom = s.left = '';
    if (this.positionValue === 'left') { s.left = '0'; s.top = '0'; s.bottom = '0'; }
    else if (this.positionValue === 'right') { s.right = '0'; s.top = '0'; s.bottom = '0'; }
    else if (this.positionValue === 'top') { s.top = '0'; s.left = '0'; s.right = '0'; }
    else { s.bottom = '0'; s.left = '0'; s.right = '0'; }

    // Apply cross-panel offset when provided (useful for stacking nested panels)
    if (this.nestedValue && this.hasOffsetValue) {
      const v = this.offsetValue;
      if (this.positionValue === 'top') s.top = v;
      else if (this.positionValue === 'bottom') s.bottom = v;
      else if (this.positionValue === 'left') s.left = v;
      else if (this.positionValue === 'right') s.right = v;
    }

    // Cross-axis full size (main dimension handled in CSS)
    if (this.positionValue === 'left' || this.positionValue === 'right') {
      s.height = this.nestedValue ? '100%' : '100vh';
      s.width = '';
    } else {
      s.width = this.nestedValue ? '100%' : '100vw';
      s.height = '';
    }
  }

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

  _getPushTargets() {
    // 1) Explicit selector takes precedence
    if (this.hasPushSelectorValue && this.pushSelectorValue) {
      try {
        const list = Array.from(document.querySelectorAll(this.pushSelectorValue));
        if (list.length) return list;
      } catch (_) { /* ignore */ }
    }
    // 2) Nested panels push their immediate parent content area if available
    if (this.nestedValue) {
      const parentPanel = this.element.parentElement;
      if (parentPanel) {
        // Prefer a content wrapper inside the parent panel
        const el = parentPanel.querySelector(':scope > .toggle-panel__content') || parentPanel;
        return el ? [el] : [];
      }
    }
    // 3) Default to main content if present, else body
    const def = document.querySelector('main') || document.body;
    return def ? [def] : [];
  }

  _expandedSize() {
    const cs = getComputedStyle(this.element);
    const vertical = (this.positionValue === 'left' || this.positionValue === 'right');
    const varName = vertical ? '--tp-expanded-size-v' : '--tp-expanded-size-h';
    // Fallback to inline values if set
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

  _applyOffset(on) {
    // Nested panels coordinate layout via content insets to avoid overlaying content
    if (this.nestedValue) { this._applyNestedLayout(); return; }

    const targets = this._getPushTargets();
    if (!targets.length) return;
    const value = on ? this._expandedSize() : '';
    const pos = this.positionValue;
    targets.forEach((target) => {
      this._ensurePaddingTransition(target);
      if (pos === 'left') target.style.paddingLeft = value;
      else if (pos === 'right') target.style.paddingRight = value;
      else if (pos === 'top') target.style.paddingTop = value;
      else target.style.paddingBottom = value;
    });
  }

  _applyNestedLayout() {
    const parent = this.element.parentElement;
    if (!parent) return;
  const target = parent.querySelector(':scope > .toggle-panel__content');
  if (!target) return; // parent content not ready yet; skip
    // Ensure positioning and transitions
    const cs = window.getComputedStyle(parent);
    if (cs.position === 'static') parent.style.position = 'relative';
    if (getComputedStyle(target).position !== 'absolute') target.style.position = 'absolute';
    this._ensureInsetTransition(target);

    const parentRect = parent.getBoundingClientRect();
    const inset = { top: 0, bottom: 0, left: 0, right: 0 };
    ['top','bottom','left','right'].forEach((edge) => {
      const selector = `:scope > [data-controller~="toggle-panel"][data-toggle-panel-nested-value="true"][data-toggle-panel-position-value="${edge}"]`;
      const items = Array.from(parent.querySelectorAll(selector));
      items.forEach((el) => {
        const r = el.getBoundingClientRect();
        if (edge === 'top') inset.top = Math.max(inset.top, r.bottom - parentRect.top);
        else if (edge === 'bottom') inset.bottom = Math.max(inset.bottom, parentRect.bottom - r.top);
        else if (edge === 'left') inset.left = Math.max(inset.left, r.right - parentRect.left);
        else inset.right = Math.max(inset.right, parentRect.right - r.left);
      });
    });

    // Apply as absolute insets so the content area visibly compresses
    target.style.top = inset.top ? `${Math.round(inset.top)}px` : '0';
    target.style.bottom = inset.bottom ? `${Math.round(inset.bottom)}px` : '0';
    target.style.left = inset.left ? `${Math.round(inset.left)}px` : '0';
    target.style.right = inset.right ? `${Math.round(inset.right)}px` : '0';
  }

  _ensurePaddingTransition(target) {
    if (!target.classList.contains('tp-animate-padding')) target.classList.add('tp-animate-padding');
  }

  _ensureInsetTransition(target) {
    if (!target.classList.contains('tp-animate-inset')) target.classList.add('tp-animate-inset');
  }

  _getPanelSizeParts(el) {
    const pos = el.getAttribute('data-toggle-panel-position-value') || 'left';
    const vertical = (pos === 'left' || pos === 'right');
    const cs = getComputedStyle(el);
    const varCollapsed = vertical ? '--tp-collapsed-size-v' : '--tp-collapsed-size-h';
    const varExpanded  = vertical ? '--tp-expanded-size-v'  : '--tp-expanded-size-h';
    let collapsed = cs.getPropertyValue(varCollapsed).trim();
    let expanded  = cs.getPropertyValue(varExpanded).trim();
    if (!collapsed) collapsed = vertical ? '2.75rem' : '2.25rem';
    if (!expanded)  expanded  = vertical ? 'min(360px, 85vw)' : 'min(40vh, 480px)';
    return { collapsed, expanded };
  }

  _isExpandedNow(el) {
    return el.classList.contains('is-sticky') || el.matches(':hover');
  }

  _updateNestedPositions() {
    if (!this.nestedValue) return;
    const parent = this.element.parentElement;
    if (!parent) return;
    ['top','bottom','left','right'].forEach((edge) => {
      const selector = `:scope > [data-controller~="toggle-panel"][data-toggle-panel-nested-value="true"][data-toggle-panel-position-value="${edge}"]`;
      const list = Array.from(parent.querySelectorAll(selector));
      if (list.length === 0) return;

      // Sort by numeric offset if possible, else DOM order
      const withOffsets = list.map(el => ({
        el,
        offset: el.getAttribute('data-toggle-panel-offset-value') || '0'
      }));
      const toPx = (v) => {
        // simple parse for rem/px values; else NaN to fallback to DOM order
        if (!v) return 0;
        if (v.endsWith('px')) return parseFloat(v);
        if (v.endsWith('rem')) return parseFloat(v) * parseFloat(getComputedStyle(document.documentElement).fontSize || '16');
        const n = parseFloat(v);
        return isNaN(n) ? NaN : n;
      };
      const allNumeric = withOffsets.every(o => !isNaN(toPx(o.offset)));
      const ordered = allNumeric ? withOffsets.sort((a,b)=>toPx(a.offset)-toPx(b.offset)) : withOffsets;

      let prefixParts = [];
      ordered.forEach((item, idx) => {
        const { el, offset } = item;
        const sizes = this._getPanelSizeParts(el);
        const sizeNow = this._isExpandedNow(el) ? sizes.expanded : sizes.collapsed;
        const sumParts = [];
        if (offset && offset !== '0') sumParts.push(offset);
        if (idx > 0) sumParts.push(...prefixParts);
        const sumExpr = sumParts.length === 0 ? (edge==='top'||edge==='left' ? '0' : '0') : (sumParts.length === 1 ? sumParts[0] : `calc(${sumParts.join(' + ')})`);
        // Apply position
        if (edge === 'top') { el.style.top = sumExpr; el.style.bottom = ''; }
        else if (edge === 'bottom') { el.style.bottom = sumExpr; el.style.top = ''; }
        else if (edge === 'left') { el.style.left = sumExpr; el.style.right = ''; }
        else { el.style.right = sumExpr; el.style.left = ''; }
        // Update prefix for next sibling
        prefixParts.push(sizeNow);
      });
    });
  }

  _isVertical() {
    return this.positionValue === 'left' || this.positionValue === 'right';
  }
}

// expose globally for application.js registration
window.TogglePanelController = TogglePanelController;
