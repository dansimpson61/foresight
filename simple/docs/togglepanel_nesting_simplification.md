# Toggle Panel Nesting Simplification Scratchpad

**Goal:** Nested toggle panels should be simple - they're just containers within containers. Current implementation has ~100 lines of complex positioning logic that should be drastically simplified.

## Current State Analysis

### Current Nested Panel Approach (Complex)

**What happens now:**
1. Nested panels use `position: absolute` 
2. Parent panel content wrapper gets `position: absolute` with calculated insets
3. JavaScript calculates bounding boxes to determine insets
4. Complex stacking logic with offset calculations
5. Recalculates on hover/sticky state changes

**Lines of code:** ~100 lines for nested positioning

**Key methods:**
- `_applyAnchors()` - Sets absolute positioning for nested panels
- `_applyNestedLayout()` - Calculates and applies insets to parent content
- `_updateNestedPositions()` - Complex stacking calculations (~40 lines!)
- `_getPanelSizeParts()` - Gets collapsed/expanded sizes
- `_isExpandedNow()` - Checks if panel is expanded
- `_ensureInsetTransition()` - Adds transition class

### Why Is This Complex?

The current approach treats nested panels as a **special case** requiring:
- Absolute positioning calculations
- Parent content wrapper manipulation  
- Bounding box measurements
- Dynamic inset adjustments
- Sibling panel stacking logic

This violates "Ode to Joy" - it's clever, not simple.

## Simplified Approach: Grid All The Way Down

### Key Insight
**A nested panel's parent IS a panel's content area.** That content area can use the same grid layout!

### Proposal: Recursive Grid Pattern

```css
/* ANY toggle panel content can be a grid container */
.toggle-panel__content {
  display: grid;
  grid-template-areas: 
    "nested-top nested-top nested-top"
    "nested-left nested-main nested-right"
    "nested-bottom nested-bottom nested-bottom";
  grid-template-rows: auto 1fr auto;
  grid-template-columns: auto 1fr auto;
}

/* Nested panels flow in their grid areas */
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="left"] { 
  grid-area: nested-left; 
}
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="right"] { 
  grid-area: nested-right; 
}
/* etc. */

/* Non-panel content takes the main area */
.toggle-panel__content > *:not(.toggle-panel) { 
  grid-area: nested-main; 
}
```

**Benefits:**
- ✅ No JavaScript positioning needed
- ✅ Same pattern recursively
- ✅ Grid handles all layout
- ✅ No bounding box calculations
- ✅ No special cases

### Alternative: Simpler Flexbox for Nested

If we only support one nested panel per edge (reasonable constraint):

```css
.toggle-panel__content {
  display: flex;
  flex-direction: column;
}

.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="top"] {
  order: -1;
}

.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="bottom"] {
  order: 1;
}

.toggle-panel__content > *:not(.toggle-panel) {
  flex: 1;
  min-height: 0;
}
```

Even simpler! Natural stacking order.

## Iteration 1: Map Current Nested Logic

### When nested=true is set:

1. **connect()** - Lines 92-103
   ```javascript
   if (this.nestedValue) {
     const parent = this.element.parentElement;
     if (parent) {
       const cs = window.getComputedStyle(parent);
       if (cs.position === 'static') parent.style.position = 'relative';
     }
   }
   ```
   **Purpose:** Ensure parent is positioned for absolute children
   **Needed?** NO - Grid doesn't need this

2. **connect()** - Lines 120-127
   ```javascript
   if (this.nestedValue) {
     this._onEnter = () => this._updateNestedPositions();
     this._onLeave = () => this._updateNestedPositions();
     this.element.addEventListener('mouseenter', this._onEnter);
     this.element.addEventListener('mouseleave', this._onLeave);
     this._updateNestedPositions();
   }
   ```
   **Purpose:** Update positions on hover state changes
   **Needed?** NO - CSS handles sizing

3. **_applyAnchors()** - Lines 145-173
   ```javascript
   _applyAnchors() {
     const s = this.element.style;
     s.top = s.right = s.bottom = s.left = '';
     if (this.positionValue === 'left') { s.left = '0'; s.top = '0'; s.bottom = '0'; }
     // ... more positioning
     if (this.nestedValue && this.hasOffsetValue) {
       // offset logic
     }
     if (this.positionValue === 'left' || this.positionValue === 'right') {
       s.height = this.nestedValue ? '100%' : '100vh';
     }
   }
   ```
   **Purpose:** Position nested panels absolutely with offsets
   **Needed?** NO - Grid areas handle this

4. **_applyNestedLayout()** - Lines 216-250
   ```javascript
   _applyNestedLayout() {
     // Find parent content wrapper
     // Measure all nested panels with getBoundingClientRect()
     // Calculate insets
     // Apply absolute positioning to content wrapper
   }
   ```
   **Purpose:** Push parent content away from nested panels
   **Needed?** NO - Grid does this automatically

5. **_updateNestedPositions()** - Lines 269-310
   ```javascript
   _updateNestedPositions() {
     // Query all nested panels on same edge
     // Sort by offset
     // Calculate cumulative positioning
     // Apply calc() expressions for stacking
   }
   ```
   **Purpose:** Stack multiple panels on same edge
   **Needed?** MAYBE - But grid can handle this too!

## Iteration 2: Identify What We Actually Need

### Core Nested Panel Requirements

1. **Panel positioning** - Which edge?
   - Grid area based on position value ✓

2. **Content flow** - Push content when panel expands
   - Grid auto-sizing ✓

3. **Multiple panels per edge** - Stack them
   - Grid implicit rows/columns ✓

4. **Panel sizing** - Collapsed/expanded widths
   - Same CSS variables work ✓

### What JavaScript Actually Needs to Do

**For nested panels:**
1. Nothing! Grid handles it all.

**Wait, really?** Let's verify...

- Positioning: Grid area
- Sizing: CSS variables (same as non-nested)
- Stacking: Grid implicit tracks
- Content flow: Grid auto-sizing
- State: Same sticky toggle

**YES, REALLY!** JavaScript just toggles classes. Grid does the rest.

## Iteration 3: Simplified JavaScript

### Remove These Methods Entirely
- ❌ `_applyAnchors()` - Grid positions elements
- ❌ `_applyNestedLayout()` - Grid handles content insets
- ❌ `_updateNestedPositions()` - Grid stacks implicitly
- ❌ `_getPanelSizeParts()` - Only used by above
- ❌ `_isExpandedNow()` - Only used by above
- ❌ `_ensureInsetTransition()` - CSS handles transitions

### Simplify These Methods
- ⚠️ `connect()` - Remove nested positioning logic (lines 79-103, 120-127)
- ⚠️ `disconnect()` - Remove nested event listeners (simpler)
- ⚠️ `toggle()` - Remove nested position updates (simpler)

### Keep These Methods
- ✅ Content wrapper creation
- ✅ Handle creation  
- ✅ Label creation
- ✅ Orientation classes
- ✅ Size variable setting
- ✅ Toggle logic
- ✅ A11y updates
- ✅ Icon updates

### New JavaScript (Estimated ~120 lines)

```javascript
class TogglePanelController extends Stimulus.Controller {
  static values = {
    position: { type: String, default: 'left' },
    collapsedSize: String,
    expandedSize: String,
    label: { type: String, default: 'Panel' },
    icon: String,
    iconsOnly: { type: Boolean, default: false }
  }
  
  // Remove: nested, offset (not needed with grid)

  static targets = ["content", "handle"]

  connect() {
    this._createContentWrapper();
    this._createHandle();
    this._createLabel();
    this._initializeClasses();
    this._setSizeVariables();
    this._initializeToggle();
  }

  disconnect() {
    if (this._onPanelClick) {
      this.element.removeEventListener('click', this._onPanelClick);
    }
  }

  toggle() {
    this.sticky = !this.sticky;
    this.element.classList.toggle('is-sticky', this.sticky);
    this._updateA11y();
    this._updateHandleIcon();
  }

  // Helper methods (same as before, but simpler)
  _createContentWrapper() { /* ... */ }
  _createHandle() { /* ... */ }
  _createLabel() { /* ... */ }
  _initializeClasses() { /* ... */ }
  _setSizeVariables() { /* ... */ }
  _initializeToggle() { /* ... */ }
  _updateA11y() { /* ... */ }
  _updateHandleIcon() { /* ... */ }
  _isVertical() { /* ... */ }
}
```

## Iteration 4: Simplified CSS for Nesting

### Current Grid (Body Level)
```css
body { 
  display: grid;
  grid-template-areas: 
    "top top top"
    "left main right"
    "bottom bottom bottom";
  grid-template-rows: auto 1fr auto;
  grid-template-columns: auto 1fr auto;
}
```

### Extend to Panel Content (Nested Level)
```css
/* Panel content can contain nested panels */
.toggle-panel__content {
  display: grid;
  grid-template-areas: 
    "nested-top nested-top nested-top"
    "nested-left nested-main nested-right"
    "nested-bottom nested-bottom nested-bottom";
  grid-template-rows: auto 1fr auto;
  grid-template-columns: auto 1fr auto;
  min-height: 0; /* Allow shrinking */
}

/* Nested panels flow to their grid areas */
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="left"] { 
  grid-area: nested-left; 
}
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="right"] { 
  grid-area: nested-right; 
}
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="top"] { 
  grid-area: nested-top; 
}
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="bottom"] { 
  grid-area: nested-bottom; 
}

/* All other content flows to main area */
.toggle-panel__content > *:not(.toggle-panel) { 
  grid-area: nested-main;
  min-height: 0; /* Allow shrinking */
  overflow: auto; /* Scroll if needed */
}

/* Multiple items in main? Stack them */
.toggle-panel__content > *:not(.toggle-panel):not(:only-child) {
  /* Could use subgrid if all in main */
}
```

### Handle Multiple Panels Per Edge
If we have 2 left panels, grid handles stacking:
```css
/* Grid will create implicit rows/columns for multiple panels */
.toggle-panel__content {
  grid-auto-rows: auto;
  grid-auto-columns: auto;
}
```

## Iteration 5: Test Cases for Nested

### Test Case 1: Single Nested Panel
```slim
== toggleleft label: "Outer Left" do
  .content-area
    p Main content here
  
  == toggleright label: "Inner Right"
    p Nested panel content
```

**Expected:**
- Outer panel at body left edge
- Inner panel at outer panel's right edge
- Main content flows between them
- Grid handles all positioning

### Test Case 2: Multiple Nested Panels
```slim
== toggleleft label: "Outer" do
  == toggletop label: "Nested Top"
    p Top content
  
  == toggleleft label: "Nested Left"  
    p Left content
  
  .main-content
    p Center content
  
  == toggleright label: "Nested Right"
    p Right content
```

**Expected:**
- All nested panels flow to grid areas
- Main content takes center
- No JavaScript calculation needed

### Test Case 3: Deep Nesting (3 levels)
```slim
== toggleleft label: "L1" do
  == toggleleft label: "L2" do
    == toggleleft label: "L3" do
      p Deep content
```

**Expected:**
- Each level creates its own grid
- Recursive pattern works naturally
- CSS handles everything

## Iteration 6: Migration Plan

### Step 1: Update CSS (Non-Breaking)
Add nested grid rules to `.toggle-panel__content`

### Step 2: Simplify JavaScript (Breaking for Complex Nested)
Remove all nested positioning logic

### Step 3: Update Ruby Helpers (Non-Breaking)
Keep `nested:` parameter for backwards compat, but it becomes a no-op

### Step 4: Update Docs
Document the new simple nesting pattern

### Step 5: Test
Verify all nesting scenarios work with pure CSS

## Final Simplified Code Size Estimate

**Current:** 322 lines
**Simplified:**
- Core logic: ~80 lines
- Helper methods: ~40 lines
- Comments: ~15 lines
**Total: ~135 lines** (58% reduction!)

**Removed methods:**
- `_applyAnchors()` - 28 lines
- `_applyNestedLayout()` - 35 lines  
- `_updateNestedPositions()` - 42 lines
- `_getPanelSizeParts()` - 13 lines
- `_isExpandedNow()` - 3 lines
- `_ensureInsetTransition()` - 3 lines
- Nested event handling - ~15 lines
**Total removed: ~139 lines**

## Decision Points

### Q1: How to handle offset parameter?
**Option A:** Remove it - grid spacing handles layout
**Option B:** Keep it as CSS custom property `--tp-offset: value`
**Recommendation:** Remove it. Grid gap or padding achieves the same.

### Q2: Multiple panels on same edge - how to stack?
**Option A:** Grid implicit tracks (auto)
**Option B:** Limit to one panel per edge
**Recommendation:** Grid implicit tracks - it "just works"

### Q3: Nested panel content wrapper position?
**Current:** Absolute with calculated insets
**New:** Grid area `nested-main`, natural flow
**Recommendation:** Natural flow, remove absolute positioning

### Q4: Transition animations for nested?
**Current:** JavaScript adds transition classes
**New:** CSS transitions on grid areas
**Recommendation:** Pure CSS, no JS needed

## Next Steps

1. ✅ Map current logic (done above)
2. ✅ Identify simplifications (done above)
3. ⏳ Implement CSS grid for nested content
4. ⏳ Remove unnecessary JavaScript
5. ⏳ Test all nesting scenarios
6. ⏳ Update documentation

---

## Implementation Code (Draft)

### CSS Addition
```css
/* Nested panel support - grid all the way down */
.toggle-panel__content {
  display: grid;
  grid-template-areas: 
    "n-top n-top n-top"
    "n-left n-main n-right"
    "n-bottom n-bottom n-bottom";
  grid-template-rows: auto 1fr auto;
  grid-template-columns: auto 1fr auto;
  min-height: 0;
  overflow: auto;
}

.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="left"] { 
  grid-area: n-left; 
}
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="right"] { 
  grid-area: n-right; 
}
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="top"] { 
  grid-area: n-top; 
}
.toggle-panel__content > .toggle-panel[data-toggle-panel-position-value="bottom"] { 
  grid-area: n-bottom; 
}

/* Non-panel content takes main area */
.toggle-panel__content > *:not(.toggle-panel) { 
  grid-area: n-main;
  min-height: 0;
}
```

### JavaScript Removals
```javascript
// DELETE these methods entirely:
// _applyAnchors() - Not needed, grid positions
// _applyNestedLayout() - Not needed, grid handles insets  
// _updateNestedPositions() - Not needed, grid stacks
// _getPanelSizeParts() - Only used by above
// _isExpandedNow() - Only used by above
// _ensureInsetTransition() - CSS handles

// SIMPLIFY connect():
connect() {
  // ... existing content/handle/label creation ...
  
  // Remove nested positioning setup
  // Remove nested event listeners
  
  // Keep: orientation classes, size variables, toggle setup
}

// SIMPLIFY toggle():
toggle() {
  this.sticky = !this.sticky;
  this.element.classList.toggle('is-sticky', this.sticky);
  this._updateA11y();
  this._updateHandleIcon();
  // Remove: nested position updates
}
```

Ready to implement?
