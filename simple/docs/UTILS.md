# Front-end utilities (simple app)

This file documents the tiny front-end utilities exposed as a global under `window.FSUtils` for the Simple app. The goal is to keep logic DRY and avoid copy/paste across controllers without adding a build step.

Available helpers

- formatCurrency(number): Consistent USD formatting with a safe fallback.
- toggleExpanded(targetEl, invokerEl?): Toggles `.hidden` and sets `aria-expanded` on the invoker for a11y.
- fetchJson(url, bodyObj): POST JSON with standard headers, throws on non-2xx, returns parsed JSON.
- storage: { loadJSON, saveJSON, remove }: Safe localStorage helpers with try/catch and warnings.
- reducedMotion(): Returns true if the OS prefers reduced motion.
- safeDestroy(chart): Destroy a Chart.js instance if present, swallow errors.
- pickYearly(results, strategy): Given API results + strategy, returns the appropriate `yearly` array.
- createChartOptions(options): Small factory that returns a Chart.js options object. Accepts overrides for tooltip callbacks, legend, and tick formatting.

Usage

Include `utils.js` before your controllers in `views/partials/_scripts.slim` so the global is available at controller load time.

Example

```html
<script src="/simple/js/utils.js"></script>
<script src="/simple/js/chart_controller.js"></script>
```

In your controller:

```js
const value = FSUtils.formatCurrency(amount);
FSUtils.toggleExpanded(this.panelTarget, event.currentTarget);
```

Notes

- These helpers are intentionally small and framework-agnostic. If a bigger pattern emerges, prefer adding small focused helpers over a large abstraction.
- Keep the public surface minimal; expand only when two or more spots need the same thing (Rule of Three).
