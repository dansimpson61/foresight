# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning (SemVer) as it evolves.

## [Unreleased]
- TBD

## [0.3.0] - 2025-09-17
### Added
- **New Visualizations:** Implemented the three core Tufte-inspired visualizations:
  - "Lifetime Asset Progression" (Net Worth Over Time) stacked bar chart.
  - "Annual Income & Tax Details" stacked bar chart with tax overlay.
  - "IRMAA Impact Timeline" color-coded bar chart.
  - "Tax-Efficiency Gauge" doughnut chart.

### Changed
- **Refactored Charting:** All charting logic is now consolidated within the `charts_controller.js` Stimulus controller, which manages all four new charts.

### Fixed
- **Critical Backend Bugs:** Resolved a series of cascading 500 errors in the `PlanService` caused by mismatches between the frontend payload and backend model expectations. This included correcting keys (`annual_expenses`, `emergency_fund_floor`) and aligning strategy names (`do_nothing`, `fill_to_top_of_bracket`) between the API and the core simulation, allowing the request specs to finally pass.

## [0.2.0] - 2025-09-17
### Added
- **Comprehensive UI Controls:** The UI now includes a full set of interactive controls for all aspects of the financial plan, including detailed income sources, assets, liabilities, spending, and withdrawal strategies.
- **Backend Unit Test:** Added a new RSpec test for the `PlanService` to validate the parsing of the new, complex data model.

### Changed
- **Major Backend Refactoring:** Overhauled the entire backend to support a comprehensive, data-driven simulation. All models (`PlanService`, `Household`, `LifePlanner`, `AnnualPlanner`, `IncomeSource`, `Account`) are now aligned with the new data strategy.
- **Filing Status-Aware Tax Engine:** The `TaxYear` model is no longer hardcoded for a single filing status. It now dynamically calculates taxes, deductions, and thresholds based on the user's selected filing status (`mfj` or `single`).
- **Frontend/Backend Alignment:** The frontend `plan_form_controller` now sends a complete, well-structured JSON payload, and the backend is fully equipped to process it, resolving numerous crashes.
- **Updated Tax Data:** Expanded `config/tax_brackets.yml` to include data for the `single` filing status.

## [0.1.1] - 2025-09-12
### Fixed
- UI: Correct Slim boolean attribute for controls form (`novalidate`).

### Added
- UI: Debounced auto-run when controls change; seed JSON from controls if empty.
- Docs: Add vendor Stimulus (3.2.1) license file.
- UI: Stronger summary metric hierarchy and spacing.

### Notes
- See `comments/comment v.0.1.1.md` for design critique and the path to joy guiding these tweaks.

---

*... (older versions remain the same)*

[Unreleased]: https://github.com/dansimpson61/foresight/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/dansimpson61/foresight/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/dansimpson61/foresight/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/dansimpson61/foresight/releases/tag/v0.1.1
[0.1.0]: https://github.com/dansimpson61/foresight/releases/tag/v0.1.0
