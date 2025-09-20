# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning (SemVer) as it evolves.

## [Unreleased]

### Added
- **New SVG Income Chart:** Implemented a new "Annual Income & Tax Details" chart using a dedicated Stimulus controller (`income_chart_controller.js`) and pure SVG for a minimalist, library-free visualization.
- **Detailed Income Breakdown:** The `AnnualPlanner` now returns a granular breakdown of all taxable income sources for each year.
- **Tax Bracket Data:** The API now provides the standard deduction and tax bracket ceilings for each year, enabling richer frontend visualizations.

### Changed
- **Refined Retirement Logic:** The `Salary` model now elegantly handles retirement by accepting an optional `retirement_age`, making the simulation more accurate and the model's responsibility clearer.
- **Simplified Conversion Strategy:** Removed the incorrect standard deduction calculation from the `BracketFill` strategy. The strategy is now simpler and more accurate, focusing solely on its core responsibility.

### Fixed
- **Corrected "Sweet Spot" Scenario:** Resolved a long-standing failure in the core `PlanService` scenario test by fixing the underlying logic flaw in the `BracketFill` strategy, ensuring conversions are now correctly calculated.
- **Harmonized Test Suite:** Repaired numerous broken tests across the suite, including request specs and model specs, by aligning them with the latest API contracts and model behaviors. Pruned several obsolete feature tests that no longer reflected the current UI.

## [0.1.5] - 2025-09-17

### Added
- New unit tests for core models: `Person`, `Account`, and `IncomeSource`.
- Granular integration tests for `AnnualPlanner` to verify event sequencing and income calculations.

### Changed
- **Testing Overhaul**: The testing strategy has been fundamentally improved from a single end-to-end scenario to a robust, multi-layered "Testing Pyramid" approach. This provides greater confidence, faster feedback, and more precise error detection. Refer to `docs/Testing_Strategy.md` for full details.
- Renamed `conversion_logic_spec.rb` to `conversion_strategies_spec.rb` for clarity.
- Enhanced `conversion_strategies_spec.rb` to cover all strategies and edge cases.
- Enhanced `tax_year_spec.rb` to include tests for capital gains, Social Security taxability, and IRMAA surcharges.

### Fixed
- Corrected a logic flaw in the `BracketFill` conversion strategy where it would incorrectly recommend a conversion even when income was already above the target ceiling.
- Fixed a bug in the `Pension` model where state-specific taxability rules were not being applied correctly.
- Corrected faulty assumptions in the `accounts_spec.rb` test regarding RMD eligibility, ensuring the test now accurately validates the code.
- Aligned the `AnnualPlanner`'s `StrategyResult` struct with the test suite by adding the `ss_taxable_baseline` field, making the model's output more transparent and verifiable.

## [0.1.3] - 2025-09-17
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

## [0.1.2] - 2025-09-17
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

[Unreleased]: https://github.com/dansimpson61/foresight/compare/v0.1.5...HEAD
[0.1.5]: https://github.com/dansimpson61/foresight/compare/v0.1.3...v0.1.5
[0.1.3]: https://github.com/dansimpson61/foresight/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/dansimpson61/foresight/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/dansimpson61/foresight/releases/tag/v0.1.1
[0.1.0]: https://github.com/dansimpson61/foresight/releases/tag/v0.1.0
