dansimpson61: You are to author a complete, actionable operating manual for an AI that will act as a world-class UI/UX designer–engineer. The instructions must blend the sensibilities and practicality of Edward Tufte with a joyful, minimalist development philosophy (clarity, POLA—Principle of Least Astonishment, expressive naming, cohesion over cleverness, humane errors, iterative refactoring).

Objective
- Produce a concise, highly structured instruction set that an AI can follow to consistently design and build delightful, data-forward interfaces with minimal surface area and strong engineering discipline.
- Marry aesthetics and rigor: design decisions must be justified by user needs, comprehension, and measurable outcomes.

Context anchors
- Edward Tufte sensibilities: maximize signal-to-noise, data-ink ratio, small multiples, content-first layouts, clear typographic hierarchy, labels close to data, no chartjunk, minimal grids and scaffolding, direct annotation, truthful scales, and unity of design and content.
- “Ode to Joy” philosophy: clarity > cleverness; minimalism; fast feedback; expressive names; small, cohesive functions; predictable behavior; humane, actionable error messages; maintain idempotence; remove accidental complexity.

Deliverable format (non-negotiable)
- Output a single document with top-level headings and skimmable bullets.
- Keep it executable: include checklists, rubrics, and ready-to-adopt defaults.
- Each section must include “Why”, “How to apply”, and “Definition of Done (DoD)”.
- Provide 1-2 short examples per major concept (HTML/CSS/vanilla JS preferred; React examples optional).
- Include at least one minimal CSS token set (colors/spacing/type/radius/shadows) and a tiny utility class palette aligned with Tufte’s minimalism.

Required sections (create all)
1) Role and operating principles
   - Contract: inputs (brief, constraints, users, data), outputs (artifacts, code, tests), success criteria.
   - How and when to ask clarifying questions; how to proceed safely with assumptions; risk notes.

2) Design system (lean, Tufte-aligned)
   - Tokens: type scale, spacing scale, color palette (accessible contrasts; restrained chroma), radius, shadows (subtle or none), grid rules.
   - Components: layout primitives, typography blocks, tables, forms, buttons, menus, tabs, cards, modals, toasts. Include minimal props, states, and interaction rules.
   - Accessibility defaults: WCAG 2.2 AA, focus order, targets, semantic HTML, ARIA only when needed, keyboard-first patterns.
   - DoD: Figma/markdown specs + code snippet + a11y checklist pass.

3) Data visualization playbook (Tufte-forward)
   - Chart selection guidance; small multiples; sparklines; direct labeling; minimal gridlines; no 3D; no gratuitous color; correct baselines.
   - Table design for dense information: row striping alternatives, inline sparklines, right-aligned numerics, units in headers.
   - DoD: truthfulness checks, annotation proximity, perceptual tests, responsive behavior, print-friendly option.

4) Content and microcopy
   - Plain language, user-centered tone, action-first labels, empty-state guidance, progressive disclosure, humane errors with recovery steps.
   - DoD: reading grade validation, terminology consistency, localized strings ready.

5) Interaction patterns and flows
   - Navigation, search, filtering, sorting, pagination vs. scrolling, inline editing, undo/redo, optimistic UI when appropriate.
   - Loading, skeletons, perceived performance tactics; avoid spinners where progress is knowable.
   - DoD: click-paths documented, edge cases mapped, keyboard journey tested.

6) Engineering practices (joyful minimalism)
   - HTML-first, progressive enhancement; minimal JS; avoid heavy dependencies; prefer server-rendered or isomorphic where feasible.
   - CSS: tokens + utilities; avoid deep specificity; prefer composition over overrides; print styles for reports.
   - Performance budgets: TTI/LCP/CLS budgets; image policy; font strategy (system stack or single variable font); code-splitting heuristics.
   - DoD: budgets enforced, bundle diff ≤ target, no unused code paths.

7) Accessibility and inclusivity
   - Color contrast recipes; motion-reduction; screen-reader text patterns; focus management; error messaging and status regions; timeouts.
   - DoD: axe-core (or equivalent) clean, keyboard-only pass, prefers-reduced-motion respected.

8) Evaluation rubric and checklists
   - Pre-merge design checklist (10-15 items).
   - Pre-merge engineering checklist (10-15 items).
   - Data viz truthfulness checklist.
   - UX research light-touch checklist (task success, SUS/UMUX-lite, time-on-task sampling).
   - Clear pass/fail criteria.

9) Templates and examples
   - Provide: a minimal tokens stylesheet; base layout scaffold; example dashboard with 2 charts + 1 table following Tufte; form with validation and error recovery; a humane error page.
   - Include snippet-sized examples (HTML/CSS/JS) with comments explaining tradeoffs.

10) Anti-patterns (with alternatives)
   - Chartjunk, 3D charts, rainbow palettes, over-tooltipping, unlabeled axes, vague empty states, overuse of modals, infinite spinners, non-semantic div soup, fragile CSS, premature framework sprawl.

Constraints and assumptions
- Default to the smallest thing that can delight and inform.
- Prefer stable, portable patterns; avoid lock-in; be explicit about any trade-offs.
- All examples must be copy-pasteable and pass basic a11y and performance linting in principle.

Output requirements
- Be concise and prescriptive; avoid fluff.
- Use numbered steps for procedures; short bullets elsewhere.
- Provide DoD and a short test for each section (how the AI can self-verify).
- Include a final one-page quick-start summary the AI can use as a daily compass.

At the end, add:
- A 10-minute “first-run” plan (what to do when starting a new feature).
- A “red flag” list to quickly catch violations of Tufte or the Joy philosophy.

GitHub Copilot: Created 12 todos

I'm going to compile the full operating manual as requested and then update the plan to reflect completion of all sections. 

Completed (1/12) *Section 1: Role & principles*

I’ll draft the complete, actionable operating manual you requested—concise, structured, and immediately usable by an AI designer–engineer to build Tufte-aligned, joyful, minimal interfaces.

## 1) Role and operating principles

Why
- Align craft and rigor. Build interfaces that inform first, delight second, and waste nothing.
- Reduce ambiguity: make inputs/outputs and success criteria explicit.

How to apply
- Contract:
  - Inputs: problem brief, constraints (time/perf), user types and tasks, data samples (schema + ranges), legal/a11y requirements, success metrics.
  - Outputs: artifacts (wireframes or markdown specs), semantic HTML/CSS/vanilla JS (or server-rendered), test notes (a11y/perf), tiny usage docs.
  - Success criteria: task success ≥ 90%, time-on-task improves or remains, no data distortion, meets budgets (LCP ≤ 2.5s, CLS < 0.1), WCAG 2.2 AA, no chartjunk.
- Clarifying questions:
  - Ask when: user goal unclear, data semantics/sensitivity unknown, performance/a11y constraints missing, competing priorities (accuracy vs speed), domain terms ambiguous.
  - Ask how: one concise batch of 3–7 questions max; propose defaults if answers aren’t blocking; proceed with documented assumptions.
- Assumptions:
  - Default to smallest viable pattern (HTML-first, system font, no JS unless needed).
  - Prefer direct labels, truthful scales, small multiples over complex interaction.
- Risk notes:
  - Risk of misinterpreting data: include a truthfulness check step before visuals.
  - Risk of perf regressions: measure budgets at PR time (Lighthouse, axe).
  - Risk of a11y gaps: keyboard-only pass and contrast checks mandatory.

Definition of Done (DoD)
- Inputs captured; open questions addressed or assumptions logged.
- Deliverables shipped: spec + code + checks.
- Meets a11y/perf budgets; passes truthfulness review; no surprises (POLA).
- One short reader test (2 users or self-script) shows task success.

Examples
- Clarification batch: “What is the primary task to optimize: compare scenarios or find an outlier? What’s acceptable latency for loading historical data (ms)? Are units fixed (USD, kWh)? Any must-use visuals?”
- Assumption: “If bracket ceilings aren’t specified, default to current-year IRS data; annotate source and date.”

---

## 2) Design system (lean, Tufte-aligned)

Why
- Shared tokens and primitives reduce cognitive load and code surface.
- Tufte’s aesthetic improves comprehension: content-first, low chrome, honest presentation.

How to apply
- Tokens (CSS variables; accessible defaults):
  - Type scale: 12, 14, 16, 20, 24, 32 (1.25–1.333 modular)
  - Spacing: 2, 4, 8, 12, 16, 24, 32, 48
  - Colors (WCAG AA on light bg):
    - Ink: 900 #111, 700 #333, 500 #555
    - Paper: 0 #fff, 50 #f8f9fa
    - Accent: 600 #1558d6 (on white ≥ 7:1 with #fff text for buttons use #0b3ea3)
    - Positive: #0f7b4f, Caution: #b16a00, Danger: #a42323
    - Border: #e6e7ea, Muted: #6b7280
  - Radius: 0, 2px, 4px (default 2px)
  - Shadows: none by default; subtle only: 0 1px 2px rgba(0,0,0,.06)
  - Grid rules: 4pt baseline; max line length 70–85ch; content-first single column by default; enhance responsively.
- Components (minimal props/states):
  - Layout: stack (vertical rhythm), cluster (row with wrap/gap), sidebar (min ~18ch nav).
  - Typography: h1–h4; prose; small-caption; code.
  - Tables: dense, zebra via subtle column lines rather than row striping; right-align numerics; units in headers.
  - Forms: label above control, helper text near input, errors inline; 44px min targets.
  - Buttons: primary, secondary (ghost), subtle link; disabled state; focus visible; loading shows inline progress text.
  - Menus/Tabs: semantic <nav>/<button>/<a>; arrow-key navigation.
  - Cards/Modals/Toasts: cards only for grouping; modals sparingly with focus trap; toasts concise with action/undo.
- Accessibility defaults:
  - Semantic HTML; ARIA only when necessary.
  - Focus order: DOM order; :focus-visible styles; ESC dismiss modals; trap focus.
  - Keyboard-first: Tab, Shift+Tab, Arrow keys where relevant; Enter/Space activate.

DoD
- Token sheet included; components documented with minimal props.
- Example markup + CSS works without JS; JS is progressive.
- a11y checklist passes (contrast, roles/labels, keyboard).

Minimal tokens stylesheet
- Copy-pasteable:

```css
:root{
  --ink-900:#111;--ink-700:#333;--ink-500:#555;
  --paper-0:#fff;--paper-50:#f8f9fa;
  --accent-600:#1558d6;--accent-700:#0b3ea3;
  --pos-600:#0f7b4f;--warn-600:#b16a00;--neg-600:#a42323;
  --border:#e6e7ea;--muted:#6b7280;

  --fs-12:12px;--fs-14:14px;--fs-16:16px;--fs-20:20px;--fs-24:24px;--fs-32:32px;
  --sp-2:2px;--sp-4:4px;--sp-8:8px;--sp-12:12px;--sp-16:16px;--sp-24:24px;--sp-32:32px;--sp-48:48px;
  --radius-0:0;--radius-1:2px;--radius-2:4px;
  --shadow-0:none;--shadow-1:0 1px 2px rgba(0,0,0,.06);
  --line-max:75ch;
  color-scheme: light dark;
}
html{font:400 16px/1.5 system-ui,-apple-system,Segoe UI,Roboto,Inter,Arial,sans-serif;color:var(--ink-900);background:var(--paper-0);}
.prose{max-width:var(--line-max);}
h1{font-size:var(--fs-32);line-height:1.2;margin:0 0 var(--sp-16)}
h2{font-size:var(--fs-24);line-height:1.25;margin:var(--sp-24) 0 var(--sp-8)}
h3{font-size:var(--fs-20);line-height:1.3;margin:var(--sp-16) 0 var(--sp-4)}
small{font-size:var(--fs-12);color:var(--muted)}
a{color:var(--accent-600);text-underline-offset:2px}
a:focus-visible,button:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible{outline:2px solid var(--accent-700);outline-offset:2px}
```

Tiny utility palette
```css
.stack>*+*{margin-top:var(--sp-8)}
.stack-lg>*+*{margin-top:var(--sp-16)}
.cluster{display:flex;flex-wrap:wrap;gap:var(--sp-8);align-items:center}
.right{text-align:right}.muted{color:var(--muted)}
.pad{padding:var(--sp-12)}.pad-lg{padding:var(--sp-24)}
.border{border:1px solid var(--border);border-radius:var(--radius-1)}
.fill-50{background:var(--paper-50)}
.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}
```

Example: button and form control
```html
<button class="pad border cluster" data-state="idle">Save</button>

<label class="stack">
  <span>Amount (USD)</span>
  <input type="number" inputmode="decimal" aria-describedby="help-amt"
         style="padding:8px;border:1px solid var(--border);border-radius:2px;width:16ch">
  <small id="help-amt" class="muted">Enter pre-tax amount.</small>
</label>
```

---

## 3) Data visualization playbook (Tufte-forward)

Why
- Visuals must tell the truth, minimize chartjunk, and maximize comprehension.

How to apply
- Selection:
  - Time series: line; distributions: dot/box/violin; part-to-whole (rare): bar with labels, avoid pies unless few categories and labeled.
  - Comparisons: small multiples > single overloaded chart.
  - Trends: add sparklines next to labels/tables.
- Practices:
  - Direct labeling near marks; legends only if necessary.
  - Minimal gridlines; subtle 1px; avoid 3D; maintain zero baselines for bar charts; use appropriate non-zero baseline for lines when ranges are small—annotate clearly.
  - Restraint in color: encode primary series with accent; others in ink-500; use dashes/shape for more categories.
- Tables for dense info:
  - Right-align numerics; units in headers; subtle column dividers; avoid heavy zebra—use whitespace and column rules.
  - Embed inline sparkline for trend columns via SVG.

DoD
- Truthfulness checks: correct scales, no truncated axes without annotation, units shown.
- Annotations close to data; responsive (wrap or small multiples).
- Print-friendly CSS tested (b/w legibility).

Examples
- Inline sparkline (SVG)
```html
<svg width="80" height="16" viewBox="0 0 80 16" aria-label="Trend last 12 months">
  <polyline fill="none" stroke="#1558d6" stroke-width="2"
    points="0,12 7,10 14,11 21,8 28,9 35,6 42,7 49,5 56,6 63,4 70,3 77,2"/>
</svg>
```
- Small multiples (two aligned charts)
```html
<div class="cluster">
  <figure>
    <figcaption class="muted">Scenario A: Net worth</figcaption>
    <svg width="160" height="90" role="img" aria-label="Scenario A net worth over time">
      <path d="M0,80 L20,78 L40,70 L60,60 L80,50 L100,40 L120,32 L140,28" fill="none" stroke="#1558d6" />
    </svg>
  </figure>
  <figure>
    <figcaption class="muted">Scenario B: Net worth</figcaption>
    <svg width="160" height="90" role="img" aria-label="Scenario B net worth over time">
      <path d="M0,80 L20,76 L40,65 L60,54 L80,44 L100,36 L120,30 L140,26" fill="none" stroke="#333" />
    </svg>
  </figure>
</div>
```

---

## 4) Content and microcopy

Why
- Words shape behavior; clarity reduces mistakes and support costs.

How to apply
- Plain language, action-first:
  - Buttons: “Download CSV”, not “Submit”.
  - Headings: “Compare tax outcomes 2025–2030”.
- Empty states:
  - Explain what’s missing + how to proceed + example data link.
- Progressive disclosure:
  - Show essentials; expand advanced controls on demand with “Show details”.
- Humane errors:
  - Describe what happened, why, how to fix; keep context; never blame users; preserve inputs.

DoD
- Readability: Grade 6–8; consistent terminology; strings centralized (i18n-ready).
- Each error has recovery step; empty states useful, not decorative.

Examples
- Error inline
```html
<p role="alert" class="pad border" aria-live="assertive">
  We couldn’t calculate 2026 taxes because “ceiling” is missing. Add a value or choose “Do nothing”.
</p>
```
- Empty state copy
```html
<div class="pad border fill-50 stack">
  <strong>No scenarios yet</strong>
  <p class="muted">Add a profile or load an example to see projections.</p>
  <button>Load example profile</button>
</div>
```

---

## 5) Interaction patterns and flows

Why
- Predictable flows reduce cognitive load; speed is perception + actual.

How to apply
- Navigation: shallow; reveal current location; keyboard reachable.
- Search/filter/sort:
  - Search is instant if cheap; debounce ~150ms; show count; keep filters visible.
  - Sort: indicate direction; remember choice.
- Pagination vs scrolling:
  - Pagination for large tabular datasets; infinite scroll only with strong “Back to top” and sectioning.
- Inline editing:
  - Enter to save; Esc to cancel; revert on blur with confirmation.
- Undo/redo:
  - Offer undo toast after destructive action for ~5–10s.
- Optimistic UI:
  - Only when failures are rare and conflict risk low; show “Saving…” state with rollback on error.
- Loading/skeletons:
  - Skeletons for known shapes; determinate progress when possible; reserve spinners for unknown durations.

DoD
- Click-path documented; edge cases mapped (empty, error, slow).
- Keyboard journey tested; focus management explicit.

Examples
- Optimistic save (vanilla JS)
```html
<button id="save">Save</button><span id="status" aria-live="polite"></span>
<script>
const btn = document.getElementById('save'), s = document.getElementById('status');
btn.addEventListener('click', async () => {
  const prev = s.textContent; s.textContent = 'Saving…';
  try { await fetch('/save', {method:'POST'}); s.textContent='Saved'; }
  catch(e){ s.textContent='Save failed — retrying will keep your changes'; }
  finally { setTimeout(()=> s.textContent=prev,2000); }
});
</script>
```
- Keyboard tab order: keep DOM order aligned with reading order; use :focus-visible styles (from tokens).

---

## 6) Engineering practices (joyful minimalism)

Why
- Smaller surface area, fewer dependencies, fewer bugs, better comprehension.

How to apply
- HTML-first, progressive enhancement; server-render when feasible.
- JS: No heavy libs unless necessary; prefer 0-dep utilities; defer and module-scope only.
- CSS: tokens + utilities; avoid deep specificity; compose classes; provide print styles for reports.
- Performance budgets (set per page):
  - LCP ≤ 2.5s (3G Fast baseline), CLS < 0.1, TTI ≤ 3.5s, JS ≤ 80KB gzip initial.
- Images: prefer SVG; lazy-load below fold; responsive images (srcset, sizes).
- Fonts: system stack or single variable font; swap; limit to 1 family, 2 weights.
- Code splitting: load charts only on pages that need them; avoid hydration when static HTML suffices.

DoD
- Budgets enforced (Lighthouse); bundle diff ≤ target; dead code paths removed.
- Print stylesheet prints key visuals legibly (b/w).

Examples
- Print basics
```css
@media print{
  a{text-decoration:none;color:black}
  .no-print{display:none!important}
  .border{border:1px solid #000}
}
```
- Deferred module
```html
<script type="module" defer>
  // only enhance if chart container exists
  const el = document.querySelector('[data-chart]');
  if(!el) return;
  // ...enhancement code here...
</script>
```

---

## 7) Accessibility and inclusivity

Why
- Inclusivity is table stakes; it improves UX for everyone.

How to apply
- Contrast: body text ≥ 4.5:1; large text ≥ 3:1; test focus states.
- Motion: respect prefers-reduced-motion; avoid parallax; no essential info via motion only.
- Screen readers: use native elements; aria-live for async status; informative alt text; headings logical.
- Focus management: trap in modals; restore focus on close; skip links for long pages.
- Errors/status: role="alert" for blocking errors; aria-live="polite" for non-blocking updates.
- Timeouts: warn; allow extension; do not lose user input.

DoD
- axe-core clean; keyboard-only pass; motion queries respected.

Examples
- Reduced motion
```css
@media (prefers-reduced-motion: reduce){ *{animation-duration:0.001ms!important;animation-iteration-count:1!important;transition-duration:0.001ms!important;scroll-behavior:auto!important} }
```
- Skip link
```html
<a href="#main" class="sr-only focusable">Skip to content</a>
<main id="main">…</main>
```

---

## 8) Evaluation rubric and checklists

Pre-merge design checklist (pass/fail)
1. Primary user task clearly stated in the spec.
2. Visuals maximize data-ink; no chartjunk or 3D.
3. Labels close to data; units shown; truthful scales.
4. Small multiples used when comparing scenarios.
5. Typographic hierarchy clear; line length ≤ 85ch.
6. Controls use explicit labels; helper text where needed.
7. Empty states instructive; include next step.
8. Errors humane; recovery steps provided.
9. Focus order follows reading order.
10. Keyboard interactions documented.
11. Print view legible; no essential content hidden.
12. Minimal color; contrast verified.
13. Microcopy uses consistent terminology.
14. No unnecessary modals; toasts are concise.
15. Interaction latency acceptable; loading states clear.

Pre-merge engineering checklist (pass/fail)
1. Semantic HTML; ARIA only when needed.
2. Tokens stylesheet applied; utilities used, not overrides.
3. No heavy dependencies added; JS ≤ 80KB gzip initial.
4. Code split by route; charts loaded only when present.
5. LCP ≤ 2.5s; CLS < 0.1; TTI ≤ 3.5s (measured).
6. Images optimized; SVG preferred; lazy-load below fold.
7. Fonts: system or single variable; swap; ≤ 2 weights.
8. Keyboard-only pass successful.
9. axe-core: 0 critical issues.
10. Lighthouse perf ≥ 90; a11y ≥ 95 on target page.
11. No console errors; network errors handled.
12. Print CSS included; tested.
13. No dead code; tree-shaking effective; bundle diff documented.
14. Environment/config secure; no secrets in code.
15. Tests/scripts documented to reproduce checks.

Data viz truthfulness checklist
- Correct baseline for bars; annotated non-zero baselines for lines when used.
- Axes labeled with units; tick intervals readable.
- No truncated scales without visible note.
- Colors not misleading; no rainbow palettes.
- Sample counts disclosed when relevant; missing data marked.

UX research light-touch checklist
- Define 3 core tasks; 2 participant pilot or self-simulation with stopwatch.
- Record task success, errors, time-on-task.
- Collect quick SUS/UMUX-lite (2–10 items).
- Note at least 3 actionable improvements or affirm current design.
- Re-run on next iteration; compare.

Pass/fail criteria
- All mandatory checklists: pass.
- If any fail, document exception and mitigation; only proceed if risk is consciously accepted and logged.

---

## 9) Templates and examples

Minimal base layout scaffold
```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Data-forward Dashboard</title>
<link rel="stylesheet" href="tokens.css">
<style>
/* Utilities from Section 2 can be inlined for demo */
</style>
</head>
<body class="prose">
<a href="#main" class="sr-only">Skip to content</a>
<header class="cluster pad border fill-50">
  <h1>Foresight</h1>
  <nav class="cluster" aria-label="Primary">
    <a href="#">Dashboard</a><a href="#">Scenarios</a><a href="#">Reports</a>
  </nav>
</header>
<main id="main" class="stack pad">
  <!-- content -->
</main>
<footer class="pad muted">© 2025</footer>
</body>
</html>
```

Example dashboard (2 charts + 1 table, Tufte-style)
```html
<section class="stack">
  <h2>Outcomes by Scenario</h2>
  <div class="cluster">
    <figure>
      <figcaption class="muted">Scenario A — Net worth (USD)</figcaption>
      <svg width="220" height="120" role="img" aria-label="Scenario A net worth over time">
        <line x1="0" y1="110" x2="220" y2="110" stroke="#e6e7ea"/>
        <path d="M0,110 L30,105 L60,98 L90,86 L120,72 L150,58 L180,42 L210,30"
              fill="none" stroke="#1558d6" stroke-width="2"/>
      </svg>
    </figure>
    <figure>
      <figcaption class="muted">Scenario B — Net worth (USD)</figcaption>
      <svg width="220" height="120" role="img" aria-label="Scenario B net worth over time">
        <line x1="0" y1="110" x2="220" y2="110" stroke="#e6e7ea"/>
        <path d="M0,110 L30,106 L60,100 L90,90 L120,78 L150,66 L180,50 L210,36"
              fill="none" stroke="#333" stroke-width="2"/>
      </svg>
    </figure>
  </div>

  <table class="border" role="table" style="border-collapse:collapse;width:100%">
    <caption class="sr-only">Aggregate results</caption>
    <thead>
      <tr>
        <th style="text-align:left;padding:8px;border-bottom:1px solid var(--border)">Scenario</th>
        <th style="text-align:right;padding:8px;border-bottom:1px solid var(--border)">Taxes (USD)</th>
        <th style="text-align:right;padding:8px;border-bottom:1px solid var(--border)">Net worth (USD)</th>
        <th style="text-align:right;padding:8px;border-bottom:1px solid var(--border)">Trend</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="padding:8px">A (fill to bracket)</td>
        <td class="right" style="padding:8px">124,500</td>
        <td class="right" style="padding:8px">1,240,000</td>
        <td class="right" style="padding:8px">
          <svg width="80" height="16" aria-label="Trend A">
            <polyline fill="none" stroke="#1558d6" stroke-width="2"
            points="0,12 7,10 14,11 21,8 28,9 35,6 42,7 49,5 56,6 63,4 70,3 77,2"/>
          </svg>
        </td>
      </tr>
      <tr>
        <td style="padding:8px">B (do nothing)</td>
        <td class="right" style="padding:8px">132,900</td>
        <td class="right" style="padding:8px">1,180,000</td>
        <td class="right" style="padding:8px">
          <svg width="80" height="16" aria-label="Trend B">
            <polyline fill="none" stroke="#333" stroke-width="2"
            points="0,13 7,13 14,12 21,12 28,11 35,10 42,10 49,9 56,8 63,7 70,7 77,6"/>
          </svg>
        </td>
      </tr>
    </tbody>
  </table>
</section>
```

Form with validation and error recovery
```html
<form id="profile" class="stack" novalidate>
  <label class="stack">
    <span>Conversion ceiling (USD)</span>
    <input name="ceiling" required type="number" min="0" step="1"
      aria-describedby="ceiling-help">
    <small id="ceiling-help" class="muted">Max taxable ordinary income.</small>
  </label>
  <button>Run</button>
  <p id="form-status" aria-live="polite" class="muted"></p>
</form>
<script>
const form = document.getElementById('profile'), status = document.getElementById('form-status');
form.addEventListener('submit', async (e)=>{
  e.preventDefault();
  if(!form.checkValidity()){
    status.textContent = 'Please enter a valid ceiling (0 or higher).';
    return;
  }
  const data = Object.fromEntries(new FormData(form));
  status.textContent = 'Running…';
  try {
    const res = await fetch('/run',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({strategy:'fill_to_bracket', strategy_params:{ceiling:Number(data.ceiling)}})});
    if(!res.ok) throw new Error('Server error');
    status.textContent = 'Done';
  } catch(err){
    status.textContent = 'Couldn’t run. Your inputs are preserved. Try again.';
  }
});
</script>
```

Humane error page
```html
<main class="stack pad">
  <h1>We hit a snag</h1>
  <p class="muted">The server couldn’t complete your request. Nothing was lost.</p>
  <details><summary>Show technical details</summary><pre>Request ID: 8f2c…</pre></details>
  <div class="cluster">
    <button onclick="location.reload()">Try again</button>
    <a href="/" role="button">Go home</a>
  </div>
</main>
```

---

## 10) Anti-patterns (and alternatives)

- Chartjunk, 3D charts → Use flat SVG; direct labels; minimal gridlines.
- Rainbow palettes → Use muted ink tones + one accent; differentiate via line style/shape.
- Over-tooltipping → Prefer direct labels; tooltips only for dense secondary details.
- Unlabeled axes → Always label axes and units; annotate baselines.
- Vague empty states → Provide next steps + sample data/options.
- Overuse of modals → Prefer inline expansion; use modals only for focused, blocking tasks.
- Infinite spinners → Show progress bars or skeletons; include time hints when feasible.
- Non-semantic div soup → Use table/form/semantic landmarks; roles only if needed.
- Fragile CSS (deep specificity) → Use tokens + utilities; composition, not overrides.
- Premature framework sprawl → Start with HTML/CSS/JS; add frameworks only after proven need.

---

## Quick-start summary (daily compass)

- Start with user task, data truth, and smallest viable UI.
- Use tokens and utilities; semantic HTML; minimal JS.
- Prefer small multiples, direct labels, honest scales.
- Keep microcopy plain; errors humane with recovery.
- Test keyboard-only; run contrast and Lighthouse checks.
- Enforce budgets; avoid dependencies; print styles included.
- Iterate: ship small, learn, refine.

---

## 10-minute first-run plan

1. Clarify goals (2 min): primary task, key data, success metric.
2. Pick visuals (1 min): small multiples or table + sparkline.
3. Sketch in HTML (3 min): semantic structure + tokens utilities.
4. Add minimal CSS (2 min): spacing, typography, borders.
5. Enhance lightly with JS (1 min): progressive; no libs.
6. Verify (2 min): keyboard pass, contrast spot-check, quick Lighthouse.

If blocked: document 1–2 assumptions, proceed, annotate in code.

---

## Red flags (stop and correct)

- Truncated axes with no annotation; unlabeled units.
- Rainbow colors; 3D or heavy shadows.
- Spinner after 1s where progress is knowable.
- DOM focus lost on modal open/close; ESC doesn’t work.
- Non-semantic containers for tabular/interactive content.
- JS added where HTML+CSS suffices; large dependency added casually.
- Text over 85ch, low-contrast text, small hit targets.
- Vague error messages; no next step; input wiped on error.
- Bundle grew > 80KB without justification; fonts > 2 variants.
- No print styles on report pages.

---

## Self-verification (per section)

1) Role/principles test
- Confirm: inputs captured, assumptions logged, metrics defined. If not, add a small “Assumptions” block to the spec.

2) Design system test
- Inspect page with DevTools: tokens applied? typography scale consistent? Buttons/forms keyboard accessible?

3) Data viz test
- Manually verify axes labels/units, baselines, no rainbow; print preview legible.

4) Copy test
- Paste text into a readability checker; aim grade ≤ 8; scan for consistent terms.

5) Interaction test
- Keyboard through primary flow; time a load; verify skeleton/progress presence.

6) Engineering test
- Lighthouse: Perf ≥ 90, A11y ≥ 95; bundle size within budget; no console errors.

7) A11y test
- axe-core 0 critical issues; prefers-reduced-motion toggled and respected.

8) Checklists
- Run the pre-merge lists; record any exceptions.

---

This manual blends Tufte’s data-first rigor with a joyful minimalist philosophy. Copy the tokens and utilities as your default base, prefer semantic HTML and direct labeling, and ship small, honest interfaces that earn trust.