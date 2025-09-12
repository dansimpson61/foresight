# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning (SemVer) as it evolves.

## [Unreleased]
- TBD – collected fixes and polish after v0.1.0

## [0.1.0] - 2025-09-12
### Added
- UI surface at `/ui` implemented with Slim and pure JS.
- External stylesheet `public/ui.css` with minimal, joyful baseline styles.
- Visualization (M2): Pure-SVG stacked area chart of end-of-year balances (Taxable, Traditional, Roth) with:
  - Thin overlay line for all-in tax per year.
  - Event tick marks from `events`.
  - Hover guideline and compact tooltip.
  - Axes, ticks, and currency labels (left balance axis, right tax axis; x-year ticks).
- IRMAA timeline: color-coded yearly segments using `irmaa_part_b`.
- Tax-Efficiency Gauge (M3): Pure-SVG bar showing end-of-horizon proportions (Taxable, Traditional, Roth) with inline labels when space allows.
- Toast component for success/failure feedback on actions.
- Sinatra API endpoints: `GET /`, `GET /strategies`, `GET /plan/example`, `POST /plan`, and `GET /ui`.
- Plan document `FRONTEND_PLAN.md` (milestones M0–M6) and design notes in `UX-UI Design Spec.md`.

### Changed
- Refined `views/ui.slim` structure: stylesheet moved to `<head>`, content in `<body>`, toast made a standalone overlay.
- README updates to reflect running the app and UI surface.

### Backend (Additive Only)
- Extended yearly result schema with:
  - `events` (including `ss_start`, `medicare`, `rmd_start`).
  - IRMAA lookback fields: `irmaa_lookback_year`, `irmaa_lookback_magi`.
- Preserved schema version `0.1.0`; no breaking changes.

### Fixed
- "Load example" button regression by setting explicit IDs, type="button", and robust JS handlers with error toasts.
- CSS leakage caused by mis-indented inline styles by extracting to `public/ui.css`.

### Notes
- Charts and gauge are implemented with pure SVG to keep dependencies minimal and performance high.
- Next up: minor polish on responsive scaling, accessibility labels, and a small UI smoke test.

[Unreleased]: https://github.com/dansimpson61/foresight/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dansimpson61/foresight/releases/tag/v0.1.0
