# Accordion & Flows Controller Refactor

**Date:** October 13, 2025  
**Philosophy:** "Ode to Joy" - HTML-first, minimal JavaScript, progressive enhancement

## Summary

Eliminated two unnecessary Stimulus controllers by embracing native HTML semantics.

## Changes Made

### 1. Removed `flows_controller.js` (Unused)

**Status:** ❌ Deleted entirely  
**Reason:** Controller was loaded but never used in any templates

**Files affected:**
- Deleted: `simple/public/js/flows_controller.js` (19 lines)
- Updated: `simple/views/partials/_scripts.slim` (removed script tag)

**Impact:** -19 lines of JavaScript

### 2. Replaced `accordion_controller.js` with Native `<details>`

**Status:** ✅ Replaced with HTML semantics  
**Reason:** Native `<details>/<summary>` provides identical functionality with zero JavaScript

#### Before (JavaScript + Custom HTML):
```slim
div data-controller="accordion"
  button.accordion-header type="button" id=header_id aria-controls=panel_id 
    aria-expanded="false" data-action="click->accordion#toggle" 
    = "Member Details"
  div.accordion-panel.hidden id=panel_id role="region" aria-labelledby=header_id
    / Content here
```

```javascript
class AccordionController extends Stimulus.Controller {
  toggle(event) {
    const header = event.currentTarget;
    const panel = header.nextElementSibling;
    if (!panel) return;
    if (window.FSUtils && FSUtils.toggleExpanded) {
      FSUtils.toggleExpanded(panel, header);
    } else {
      const isHidden = panel.classList.toggle('hidden');
      header.setAttribute('aria-expanded', String(!isHidden));
    }
  }
}
```

#### After (Native HTML Only):
```slim
details.accordion-panel
  summary.accordion-header Member Details
  .accordion-panel__content
    / Content here
```

**No JavaScript needed!** The browser handles:
- ✅ Click to toggle
- ✅ Keyboard navigation (Enter/Space)
- ✅ Accessibility (ARIA implicit)
- ✅ State management
- ✅ Open/close animation (via CSS)

**Files affected:**
- Deleted: `simple/public/js/accordion_controller.js` (14 lines)
- Updated: `simple/views/partials/_profile_editor.slim` (converted 2 accordion sections)
- Updated: `simple/views/partials/_scripts.slim` (removed script tag)
- Note: `simple/views/partials/_flows_panel.slim` already used native `<details>` ✨

**Impact:** -14 lines of JavaScript, +0 lines of HTML (same element count, simpler structure)

## Metrics

### JavaScript Reduction
- `flows_controller.js`: -19 lines
- `accordion_controller.js`: -14 lines
- **Total: -33 lines of JavaScript removed**

### Complexity Reduction
- Removed 2 controller files
- Removed 2 Stimulus controller registrations
- Removed dependency on `FSUtils.toggleExpanded()` in these contexts
- Eliminated all manual ARIA attribute management
- Eliminated all custom event handlers for expand/collapse

### Functionality
- ✅ **Same user experience** - click to expand/collapse
- ✅ **Better accessibility** - native browser semantics
- ✅ **Better keyboard support** - browsers handle this well
- ✅ **Progressive enhancement** - works without JavaScript
- ✅ **Simpler maintenance** - fewer moving parts

## CSS Support

The existing CSS already supports native `<details>`:

```css
/* Native <details> accordion styling */
details.accordion-panel { margin-top: 1rem; }
details.accordion-panel > summary { list-style: none; }
details.accordion-panel > summary::-webkit-details-marker { display: none; }

.accordion-header { 
  cursor: pointer; 
  padding: 1rem; 
  background-color: #f8f8f8; 
  /* ... */
}

.accordion-header:hover, 
details[open] > summary.accordion-header { 
  background-color: #f0f0f0; 
}

.accordion-panel__content { 
  padding: 1.5rem; 
  border: 1px solid var(--border); 
  /* ... */
}
```

## Benefits

### 1. **Zero JavaScript** for Accordions
Native `<details>` requires no JavaScript:
- Browser handles click events
- Browser manages `open` attribute
- Browser provides keyboard navigation
- Browser implements ARIA semantics

### 2. **Progressive Enhancement**
Works perfectly without JavaScript:
- Essential functionality preserved
- Graceful degradation
- Faster page loads
- No Flash of Unstyled Content (FOUC)

### 3. **Accessibility**
Better than our custom implementation:
- Native keyboard support (Enter, Space)
- Proper focus management
- Screen reader compatibility
- No ARIA maintenance needed

### 4. **Maintainability**
Simpler codebase:
- Fewer files to maintain
- Less coupling between JS/HTML
- Easier to understand
- Less prone to bugs

### 5. **Performance**
- 33 fewer lines to parse
- 2 fewer controller instances
- No event listener overhead
- Faster initial render

## Testing

### Manual Testing Checklist
- [x] Profile editor member sections expand/collapse
- [x] Profile editor household section expands/collapses
- [x] Flows panel expands/collapses
- [x] Keyboard navigation works (Tab, Enter, Space)
- [x] Visual styling matches previous implementation
- [x] No console errors
- [x] Works without JavaScript enabled

### Cross-browser Compatibility
Native `<details>` is supported in:
- ✅ Chrome/Edge (12+)
- ✅ Firefox (49+)
- ✅ Safari (6+)
- ✅ All modern browsers

## Future Opportunities

### Similar Patterns to Review
Other controllers use `FSUtils.toggleExpanded()` for simple show/hide:
- `chart_controller.js` - table toggle (could use `<details>`)
- `simulation_controller.js` - editor toggle (could use `<details>`)
- `profile_controller.js` - editor toggle (could use `<details>`)

These are candidates for conversion to native `<details>` in future refactors.

### Recommendation
Consider a broader pattern:
```slim
/ Instead of this:
button data-action="click->controller#toggle" Toggle
div.hidden Content

/ Use this:
details
  summary Toggle
  div Content
```

## Conclusion

By embracing native HTML semantics, we:
- ✅ Deleted 33 lines of JavaScript
- ✅ Removed 2 controller files
- ✅ Improved accessibility
- ✅ Enhanced maintainability
- ✅ Achieved progressive enhancement

**This aligns perfectly with "Ode to Joy" philosophy: Let HTML do what HTML does best!**

---

## Related Documents
- `togglepanel_grid_refactor.md` - CSS Grid refactor (~80 lines removed)
- `togglepanel_nesting_simplification.md` - Nested panels refactor (~154 lines removed)
- `REFACTOR_CONTROLLERS_PROMPT.md` - Full refactoring guide

## Next Steps
1. Consider converting other `toggleExpanded` usages to `<details>`
2. Review chart controller's table toggle
3. Review editor toggles in profile/simulation controllers
