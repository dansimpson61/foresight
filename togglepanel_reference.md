# Toggle Panel Quick Reference

> **Philosophy**: Hover to preview, click to stick. CSS-driven, minimally JS-enhanced edge panels.

## Quick Start

```slim
/ Simple left panel
== toggleleft label: "Tools" do
  p Your content here

/ Right panel with icon
== toggleright label: "Settings", icon: "⚙️" do
  ul
    li Option 1
    li Option 2

/ Top panel (horizontal)
== toggletop label: "Filters" do
  form ...
```

## All Helper Methods

| Method | Position | Example |
|--------|----------|---------|
| `toggleleft` | Left edge | `== toggleleft label: "Nav" do` |
| `toggleright` | Right edge | `== toggleright label: "Info" do` |
| `toggletop` | Top edge | `== toggletop label: "Search" do` |
| `togglebottom` | Bottom edge | `== togglebottom label: "Debug" do` |
| `togglepanel` | Any (via arg) | `== togglepanel :left, label: "Nav" do` |

## Parameters

### Essential (Use These)

| Parameter | Type | Purpose | Example |
|-----------|------|---------|---------|
| `label:` | String | Panel title (required) | `label: "Tools"` |
| `icon:` | String | Emoji/char decoration | `icon: "🧰"` |

### Layout Control (Nested Panels)

| Parameter | Type | Purpose | Example |
|-----------|------|---------|---------|
| `nested:` | Boolean | Position inside parent | `nested: true` |
| `offset:` | String | Distance from edge | `offset: "2.5rem"` |
| `push:` | String | Elements to compress | `push: "#main"` |

### Size Override (Rarely Needed)

| Parameter | Type | Purpose | Default |
|-----------|------|---------|---------|
| `collapsed:` | String | Size when closed | Vertical: `2.75rem`, Horizontal: `2.25rem` |
| `expanded:` | String | Size when open | Vertical: `min(360px, 85vw)`, Horizontal: `min(40vh, 480px)` |

### Advanced (Auto-calculated)

| Parameter | Type | Purpose | Note |
|-----------|------|---------|------|
| `icons_only:` | Boolean | Hide label text | Auto `true` for vertical panels |
| `content` | String | Static content | Prefer block syntax instead |

## Common Patterns

### 1. Simple Viewport Panel

```slim
/ Pushes main content when opened
== toggleleft label: "Navigation", icon: "☰", push: "#main" do
  nav
    ul
      li: a href="/" Home
      li: a href="/about" About
```

**Result**: Left panel at viewport edge, expands to 360px on hover/click

### 2. Nested Panel Group

```slim
/ Parent panel
== toggleleft label: "Tools", icon: "🧰", push: "header, #main" do
  
  / Child panels stack vertically
  == toggletop label: "Editor", nested: true, offset: "0" do
    textarea ...
  
  == toggletop label: "Preview", nested: true, offset: "2.5rem" do
    .preview-area ...
```

**Result**: Tools panel contains two stacked top panels

### 3. Debug Panel (Bottom)

```slim
/ Only visible in development
- if ENV['RACK_ENV'] == 'development'
  == togglebottom label: "Dev Tools", icon: "🔧" do
    pre= JSON.pretty_generate(debug_info)
```

**Result**: Bottom panel for debugging (doesn't push content)

## Behavior

### States

| State | Trigger | Width/Height | Content Visible | Sticky |
|-------|---------|--------------|-----------------|--------|
| **Collapsed** | Default | Collapsed size | ❌ No | ❌ |
| **Hovering** | Mouse over | Expanded size | ✅ Yes | ❌ |
| **Sticky** | Click | Expanded size | ✅ Yes | ✅ |

### Interactions

- **Hover**: Panel expands temporarily (CSS `:hover`)
- **Click anywhere**: Toggle sticky state (JS)
- **Click outside**: Panel stays sticky (intentional)
- **Hover when sticky**: No change (already expanded)

### Keyboard Support

- **Tab**: Focus moves to handle button
- **Enter/Space**: Toggles sticky state
- **Shift+Tab**: Focus moves back

## Styling Hooks

### CSS Custom Properties

Override per-instance via helper parameters or CSS:

```css
/* Global defaults in app.css */
.toggle-panel {
  --tp-collapsed-size-v: 2.75rem;    /* vertical collapsed */
  --tp-expanded-size-v: min(360px, 85vw);  /* vertical expanded */
  --tp-collapsed-size-h: 2.25rem;    /* horizontal collapsed */
  --tp-expanded-size-h: min(40vh, 480px);  /* horizontal expanded */
  --tp-duration: 200ms;              /* transition speed */
}

/* Override specific instance */
.my-wide-panel {
  --tp-expanded-size-v: 500px;
}
```

### CSS Classes

| Class | Purpose |
|-------|---------|
| `.toggle-panel` | Root element |
| `.toggle-panel.is-vertical` | Left/right positioned |
| `.toggle-panel.is-horizontal` | Top/bottom positioned |
| `.toggle-panel.is-sticky` | Clicked to stay open |
| `.toggle-panel.is-icons-only` | Text label hidden |
| `.toggle-panel__content` | Inner content wrapper |
| `.toggle-panel__label` | Upper-left label |
| `.toggle-panel__handle` | Toggle button |
| `.toggle-panel__icon` | Icon span |
| `.toggle-panel__text` | Label text span |

### Data Attributes

All parameters become `data-toggle-panel-*-value` attributes:

```html
<div data-controller="toggle-panel"
     data-toggle-panel-position-value="left"
     data-toggle-panel-label-value="Tools"
     data-toggle-panel-icon-value="🧰"
     data-toggle-panel-push-selector-value="#main"
     data-toggle-panel-nested-value="false">
  ...
</div>
```

## Best Practices

### ✅ DO

- Use expressive labels: `label: "Navigation"` not `label: "Nav"`
- Provide icons for visual clarity: `icon: "☰"`
- Nest panels for complex layouts: `nested: true`
- Use `push:` to compress main content: `push: "#main"`
- Rely on CSS defaults for sizing (rarely override)

### ❌ DON'T

- Specify redundant parameters: `push: nil` (just omit it)
- Override sizes without reason: `collapsed: "2.75rem"` (that's default)
- Use both `content` and block: `toggleleft "Text" do ... end` (pick one)
- Nest more than 3 levels deep (complexity grows exponentially)

### ⚠️ AVOID

- Over-parameterizing: `toggleleft label: "X", collapsed: "2.75rem", expanded: "360px", icons_only: true, push: nil, offset: "0" do`
  - Better: `toggleleft label: "X" do`
- String CSS selectors for push (fragile): `push: "div.main > section#content"`
  - Better: `push: "#main"` (simple, stable selector)

## Troubleshooting

### Panel doesn't expand on hover

**Cause**: CSS `:hover` not working  
**Fix**: Check browser DevTools, ensure `.toggle-panel:hover` rule applies

### Nested panel overlays content

**Cause**: Parent not positioned  
**Fix**: Parent auto-gets `position: relative`, but check for `static` override

### Stacking offset wrong

**Cause**: `offset:` values not cumulative  
**Fix**: Each panel's offset is from edge (0, 2.5rem, 5rem for 3 panels)

### Click doesn't toggle sticky

**Cause**: JavaScript not loaded or error  
**Fix**: Check browser console for errors, verify `toggle_panel_controller.js` loads

## Examples from Codebase

### Playground.slim (Complex Nesting)

```slim
/ Tools panel (left edge)
== toggleleft label: "Tools", icon: "🧰", push: "header, #main" do
  
  / Profiles editor (nested top)
  == toggletop label: "Profiles", nested: true, expanded: "30vh", offset: "0" do
    h3 Profiles Editor
  
  / Simulation editor (nested top, stacked below)
  == toggletop label: "Simulation", nested: true, expanded: "30vh", offset: "2.25rem" do
    h3 Simulation Editor
  
  / Dev tools (nested bottom)
  == togglebottom label: "Dev", nested: true do
    h3 Developer Helpers
```

## Architecture Summary

```
Ruby Helper (ui_helpers.rb)
    ↓
Slim Template (togglepanel.slim)
    ↓
HTML with data-controller="toggle-panel"
    ↓
Stimulus Controller (toggle_panel_controller.js)
    ↓
CSS Styles (app.css)
    ↓
User Experience
```

**Key Files**:
- `/simple/lib/helpers/ui_helpers.rb` - Ruby interface
- `/simple/views/helpers/togglepanel.slim` - Markup template
- `/simple/public/js/toggle_panel_controller.js` - Behavior
- `/simple/public/css/app.css` - Visual styling

## Related Documentation

- Philosophy: `/Ode to Joy - Ruby and Sinatra.txt`
- Design Guide: `/docs/AI_Agent_UI-UX.md`
- Full Analysis: `/togglepanel_analysis.md`
- Flow Diagrams: `/togglepanel_flow.md`

---

**Version**: 1.0 (October 10, 2025)  
**Status**: Production-ready, dual implementation cleanup recommended
