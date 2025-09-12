# Foresight Front-End Plan (Living Document)

This is a concise, updateable plan to build the joyful, minimal front end for Foresight, aligned with the UX/UI Design Spec and the Ode to Joy philosophy.

Last updated: 2025-09-11

---

## 1) Purpose & Goals

- Deliver a calm, clear interface for high-level budgeting estimation and scenario comparison.
- Make the data the star: minimal chrome, predictable interactions, fast feedback.
- Keep the runtime tiny: Sinatra + Slim + a sprinkling of Stimulus; minimal JS.

Non-goals: full financial planning, exhaustive tax parameter modeling, complex persistence.

---

## 2) Principles (Ode to Joy applied)

- Clarity over cleverness; POLA everywhere.
- Minimal UI, minimal JS; server-rendered by default.
- Small, cohesive components with intention-revealing names.
- Add tests for new behavior; keep contracts stable and versioned.

---

## 3) Scope & Milestones

M0 — Foundations (Done)
- [x] API endpoints: GET /, GET /strategies, POST /plan
- [x] Example payload: GET /plan/example
- [x] Minimal UI placeholders: GET /plan (helper) and GET /ui
- [x] Back-end enhancements: yearly `events`, `irmaa_lookback_year/magi`

M1 — UI Skeleton & Data Table (Done)
- [x] /ui: parameters textarea with example loader and Run button
- [x] Render results.yearly into a clean, scrollable table with money formatting
- [x] Toggle between strategies (dropdown)
- [x] Summary cards (lifetime taxes, total conversions, end balances)

M2 — Primary Visualization (In progress)
- [x] Stacked area chart of end-of-year balances (Taxable, Traditional, Roth)
- [x] Thin overlay line: all-in tax per year
- [x] Event annotations using `events` (year ticks)
- [x] Hover: vertical guideline + compact tooltip
- [x] Axis ticks/labels and responsive viewBox scaling polish

M3 — IRMAA Timeline & Tax-Efficiency Gauge
- [x] IRMAA timeline: color-coded yearly segments using `irmaa_part_b`
- [x] Gauge: end-of-horizon proportions of Roth (tax-free) vs Traditional (tax-deferred)

M4 — Controls & Joyful Feedback
- [ ] Lightweight controls form (age, state, balances, assumptions, strategy)
- [ ] Inline sparklines beside key sliders/inputs (pure SVG)
- [ ] Auto-run on change with debounced POST /plan

M5 — Quality, Accessibility, and Polish
- [ ] WCAG AA contrast, clear focus states, semantic HTML
- [ ] Keyboard navigation and ARIA labels on controls
- [ ] “Download JSON” button and print-friendly table view
- [ ] Perf check: 35-year run under 150ms on dev machine (target)

M6 — Optional Persistence & Compare
- [ ] Save/load scenarios to localStorage (namespaced)
- [ ] Side-by-side compare (Your Strategy vs Do Nothing) with smooth transition

---

## 4) Architecture Overview

- Server: Sinatra classic app (`app.rb`), `config.ru` for rackup.
- Views: Slim templates under `views/` (currently `ui.slim`).
- JS: A few small Stimulus controllers for:
  - params-form (collect/validate, post, debounce)
  - results-view (table render, number formatting)
  - chart-view (uPlot or pure SVG)
- CSS: minimal, inline or a tiny stylesheet; no frameworks.

Libraries (lean):
- Pure SVG (no chart lib) for stacked area + overlay line and gauge.
- No CSS framework; typography via system fonts.

---

## 5) Data Contracts (stable keys)

Input (POST /plan) — see `README.md` and `/plan/example`.

Output (POST /plan) — schema_version `0.1.0`:
- `data.inputs`: start_year, years, inflation_rate, growth_assumptions, members, accounts, income_sources, desired_tax_bracket_ceiling
- `data.results[strategy].aggregate`: cumulative taxes, conversions, ending balances, projected_first_rmd_pressure
- `data.results[strategy].yearly[]` rows include:
  - balances: `ending_traditional_balance`, `ending_roth_balance`, `ending_taxable_balance`
  - taxes: `federal_tax`, `capital_gains_tax`, `state_tax`, `all_in_tax`, `effective_tax_rate`
  - strategy: `requested_roth_conversion`, `actual_roth_conversion`
  - IRMAA: `magi`, `irmaa_part_b`, `irmaa_lookback_year`, `irmaa_lookback_magi`
  - annotations: `events` [{type:'ss_start'|'medicare'|'rmd_start', person:'Name'}]

Contract rules:
- Additive only changes for 0.x; no renames or deletions without bumping schema_version.
- Rounding rules: calculations precise internally; round for UI display.

---

## 6) Pages & Routes

- GET `/ui`: primary interface (controls + visualizations + table)
- POST `/plan`: run a plan
- GET `/strategies`: list available strategies
- GET `/plan/example`: sample payload (for demos/tests)

---

## 7) Components (first pass)

- ControlsPanel (Slim): minimal form + JSON editor toggle
- SummaryCards: lifetime taxes, total conversions, end balances, tax-free %
- StackedAreaChart (uPlot): assets with overlay tax line; annotations from `events`
- IRMAATimeline: horizontal segments per year (color-coded by tier)
- EfficiencyGauge: end-horizon bar split (Roth vs Traditional)
- ResultsTable: sticky header, number formatting, optional inline sparklines

---

## 8) Accessibility & Internationalization

- WCAG AA contrast and focus rings
- Semantic headings, labeled inputs, table headers
- Tabular figures for numerals in tables
- Money formatting: US locale initially, keep a single formatter for future i18n

---

## 9) Testing & Quality Gates

- Server smoke tests: endpoints return 200 and valid JSON keys
- JSON contract checks for `yearly` and `aggregate` keys
- UI smoke: a minimal Capybara test to load /ui and run example
- Perf: run 35-year plan twice; ensure stable timings; report P95 locally

---

## 10) Risks & Mitigations

- Visualization bloat → pick one tiny lib (uPlot) or pure SVG; avoid large deps
- Rounding inconsistencies → centralize money formatting at render
- IRMAA mapping nuances → explicit lookback fields already added
- Browser variance → use system fonts, avoid exotic CSS/JS features

---

## 11) Acceptance Criteria (M1–M3)

- M1: /ui loads; user can load example, run plan, see table + summary cards
- M2: stacked area with overlay tax line; hover tooltips; event markers
- M3: IRMAA timeline displayed with correct lookback MAGI mapping; efficiency gauge visible

---

## 12) Work Journal (Decision Log)

- 2025-09-11: Decided to use Slim + tiny Stimulus, uPlot or pure SVG for charts. Added `events` and `irmaa_lookback_*` to backend.
- 2025-09-11: Implemented pure SVG stacked area + tax overlay, IRMAA timeline, and hover tooltip.
- 2025-09-12: Added axis ticks/labels, right-axis tax labels, and a Tax-Efficiency Gauge (pure SVG). Fixed HTML structure in `ui.slim`.

---

## 13) Next Actions (short)

- Implement ResultsTable with money formatting and strategy toggle
- Add SummaryCards using `aggregate`
- Wire uPlot for stacked area + tax overlay
- Render IRMAA timeline from lookback MAGI

---

## 14) How to Run (dev)

```fish
cd /home/dan/dev/foresight
bundle install
bundle exec rackup --port 9292
# Open http://127.0.0.1:9292/ui
```

---

If scope shifts, update this document first, then the UI.