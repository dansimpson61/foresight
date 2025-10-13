# AI Coding Prompt: Apply "Ode to Joy" Philosophy to Stimulus Controllers

## Context

You're working on the **Foresight** financial planning application, which follows an "Ode to Joy" development philosophy emphasizing:
- **Minimal JavaScript** - Let CSS do what CSS does best
- **CSS-first approach** - Declarative layout over imperative manipulation
- **Expressive naming** - Clear, self-documenting code
- **DRY principle** - No repetition, single source of truth
- **POLA (Principle of Least Astonishment)** - Predictable, obvious behavior
- **Clarity over cleverness** - Simple solutions that just work

## Recent Success: Toggle Panel Refactor

We recently refactored `toggle_panel_controller.js` with spectacular results:

### What We Eliminated ✂️
- **~80 lines of coupling logic** - Removed explicit "push" mechanism
- **Position: fixed overlays** - Switched to CSS Grid natural flow
- **DOM manipulation for layout** - Grid handles all positioning
- **Explicit push parameters** - No more `push: ".selector"` needed
- **Complex target selection** - No `_getPushTargets()` logic

### What We Achieved ✨
```css
/* Pure CSS Grid layout - panels and content flow naturally */
body { 
  display: grid;
  grid-template-areas: 
    "top top top"
    "left main right"
    "bottom bottom bottom";
  grid-template-rows: auto 1fr auto;
  grid-template-columns: auto 1fr auto;
}

.toggle-panel[data-toggle-panel-position-value="left"] { grid-area: left; }
.page-container { grid-area: main; }
```

**JavaScript role reduced to:**
- State management only (sticky class toggle)
- Progressive enhancement (icons-only when collapsed)
- Accessibility (ARIA attributes)

**Result:** Panels and content flow around each other naturally - zero coupling, declarative layout, ~100 lines removed.

## Your Mission

Review the remaining Stimulus controllers and apply the same philosophy where appropriate:

### Controllers to Review

1. **`flows_controller.js`** - Manages flow visualization panels
2. **`accordion_controller.js`** - Collapse/expand behavior
3. **`chart_controller.js`** - Chart rendering and table toggle
4. **`results_controller.js`** - Results display and interactions
5. **`simulation_controller.js`** - Simulation controls
6. **`profile_controller.js`** - Profile editing forms
7. **`viz_controller.js`** - Visualization mode switching
8. **`net_worth_chart_controller.js`** - Net worth chart rendering

### Questions to Ask for Each Controller

#### 1. Layout & Positioning
- **Is JavaScript manipulating DOM for layout?** → Move to CSS Grid/Flexbox
- **Are there explicit positioning calculations?** → Use CSS positioning
- **Do elements need to "know about" other elements?** → Use CSS relationships (`:has()`, sibling selectors, grid)

#### 2. State Management
- **Is state stored in JS variables?** → Could it be CSS classes + `:hover`/`:focus` states?
- **Are there complex show/hide mechanisms?** → CSS `display: none` with class toggles
- **Is there animation/transition logic in JS?** → CSS transitions/animations

#### 3. Data Flow
- **Are there redundant parameters?** → Eliminate coupling
- **Is data passed via attributes when CSS could handle it?** → Use CSS custom properties
- **Are selectors hardcoded?** → Use data attributes or semantic structure

#### 4. Code Clarity
- **Can anyone understand this in 6 months?** → Simplify
- **Are there >50 line methods?** → Break down or question necessity
- **Is the "magic" obvious?** → Make it declarative

### Specific Refactoring Opportunities

#### Pattern 1: Replace JS Layout with CSS Grid
**Before:**
```javascript
_updateLayout() {
  const target = document.querySelector(this.pushSelectorValue);
  target.style.paddingLeft = this.isOpen ? '300px' : '0';
}
```

**After:**
```css
.container { 
  display: grid; 
  grid-template-columns: auto 1fr; 
}
.sidebar { grid-area: sidebar; }
.main { grid-area: main; }
```

#### Pattern 2: Replace JS State with CSS Classes
**Before:**
```javascript
this.expanded = false;
toggle() {
  this.expanded = !this.expanded;
  this.element.style.height = this.expanded ? 'auto' : '0';
}
```

**After:**
```css
.accordion { height: 0; transition: height 200ms; }
.accordion.is-expanded { height: auto; }
```
```javascript
toggle() {
  this.element.classList.toggle('is-expanded');
}
```

#### Pattern 3: Progressive Enhancement
**Before:**
```javascript
// Heavy JS initialization, breaks without JS
```

**After:**
```css
/* Works without JS, enhanced with JS */
.component { /* sensible defaults */ }
.component.is-enhanced { /* progressive enhancements */ }
```

#### Pattern 4: Use CSS Custom Properties for Dynamic Values
**Before:**
```javascript
this.element.style.width = `${this.calculateWidth()}px`;
```

**After:**
```javascript
this.element.style.setProperty('--dynamic-width', `${this.calculateWidth()}px`);
```
```css
.element { width: var(--dynamic-width, 100%); }
```

### Deliverables

For each controller you refactor, provide:

1. **Analysis Document** (like `togglepanel_grid_refactor.md`)
   - What was the problem?
   - What coupling existed?
   - What was the solution?
   - How does it work now?
   - What are the benefits?

2. **Updated Code**
   - Simplified JavaScript (state management only)
   - Enhanced CSS (layout, transitions, states)
   - Updated Ruby helpers (if applicable)
   - Updated templates (if applicable)

3. **Before/After Metrics**
   - Lines of JavaScript removed
   - Lines of CSS added (should be fewer than JS removed)
   - Parameters eliminated
   - Complexity reduction

4. **Testing Notes**
   - What should work the same?
   - What new capabilities emerged?
   - Any edge cases to verify?

### Design System Integration

All refactors must use the existing token system:

```css
/* Spacing: Use --sp-* tokens (4pt grid) */
margin: var(--sp-16);  /* NOT: margin: 16px */

/* Typography: Use --fs-* scale */
font-size: var(--fs-20);  /* NOT: font-size: 1.25rem */

/* Colors: Use semantic tokens */
color: var(--ink-700);  /* NOT: color: #333 */
background: var(--paper-50);  /* NOT: background: #f8fafc */

/* Borders/Radius: Use design tokens */
border-radius: var(--radius-1);  /* NOT: border-radius: 4px */
```

### Success Criteria

A successful refactor:
- ✅ **Reduces JavaScript** by eliminating layout/positioning code
- ✅ **Increases CSS declarativeness** using Grid/Flexbox/modern selectors
- ✅ **Eliminates coupling** between components
- ✅ **Simplifies API** by removing unnecessary parameters
- ✅ **Maintains functionality** - everything works the same or better
- ✅ **Improves maintainability** - code is more obvious
- ✅ **Embraces progressive enhancement** - works without JS where possible
- ✅ **Uses design tokens consistently** - no magic numbers

### Anti-Patterns to Avoid

❌ **Don't:** Move imperative JS to imperative CSS  
✅ **Do:** Make it declarative in CSS

❌ **Don't:** Add complexity to "modernize"  
✅ **Do:** Simplify ruthlessly

❌ **Don't:** Break existing functionality  
✅ **Do:** Test thoroughly, maintain behavior

❌ **Don't:** Use CSS hacks or browser-specific tricks  
✅ **Do:** Use modern, well-supported CSS (Grid, Flexbox, `:has()`, custom properties)

❌ **Don't:** Inline styles in JavaScript  
✅ **Do:** Use classes and custom properties

### Example Workflow

1. **Analyze** - Read current controller, identify coupling/complexity
2. **Question** - Ask "Does JS need to do this, or can CSS?"
3. **Design** - Sketch CSS-first solution using Grid/Flexbox
4. **Implement** - Update CSS, simplify JS, update helpers
5. **Test** - Verify all states, interactions, edge cases
6. **Document** - Write clear explanation with before/after
7. **Commit** - Descriptive message following existing patterns

### Files in Scope

```
simple/
├── public/
│   ├── css/
│   │   └── app.css                    # Main stylesheet with tokens
│   └── js/
│       ├── flows_controller.js        # Review & refactor
│       ├── accordion_controller.js    # Review & refactor
│       ├── chart_controller.js        # Review & refactor
│       ├── results_controller.js      # Review & refactor
│       ├── simulation_controller.js   # Review & refactor
│       ├── profile_controller.js      # Review & refactor
│       ├── viz_controller.js          # Review & refactor
│       └── net_worth_chart_controller.js  # Review & refactor
├── lib/helpers/
│   └── ui_helpers.rb                  # Ruby helpers (if applicable)
└── views/
    ├── helpers/                       # Component templates
    └── *.slim                         # Page templates
```

### Reference Materials

Study these successful refactor documents:
- `simple/docs/togglepanel_grid_refactor.md` - Complete grid refactor explanation
- `simple/docs/togglepanel_label_fix.md` - Progressive enhancement example
- `togglepanel_understanding.md` - Original analysis approach
- `togglepanel_analysis.md` - Deep dive methodology

### Philosophy Reminder: "Ode to Joy"

The goal is **JOYFUL** code:
- **J**avascript minimized
- **O**bvious and declarative
- **Y**ielding to CSS for layout
- **F**unctional without complexity
- **U**nderstandable at a glance
- **L**asting and maintainable

If a refactor doesn't bring joy (simplicity, clarity, elegance), reconsider the approach.

---

## Your Task

Start with **`flows_controller.js`** and **`accordion_controller.js`** as they likely have similar opportunities to what we found in toggle panels.

For each:
1. Analyze current implementation
2. Identify layout/positioning logic that could move to CSS
3. Design CSS Grid/Flexbox solution
4. Implement refactor
5. Document changes
6. Test thoroughly
7. Move to next controller

Aim for the same dramatic improvement we achieved with toggle panels: **~80 lines removed, zero coupling, pure CSS layout, simplified API**.

Let the grid flow naturally! 🎵
