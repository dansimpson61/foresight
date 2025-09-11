# Joyful Retirement Planner

This project is a Ruby implementation of a retirement income planning model, developed according to the "Ode to Joy" development philosophy. It is an exercise in craftsmanship, aiming to build a tool that is not only functional but also elegant and satisfying to work with.

## Guiding Principles

Our development is guided by a few core tenets that ensure the final model is robust, understandable, and sustainable.

* **Clarity and Expressiveness:** The code should read like well-written prose. This is especially vital in a domain as complex as tax planning, which is often perceived as opaque. Our goal is for the code itself to serve as a form of documentation, making the underlying financial logic transparent and allowing developers to intuitively grasp how tax rules are applied and strategic decisions are made.

* **Focused Purpose:** Each class and method has a single, well-defined responsibility that directly reflects a real-world financial concept. For example, a `Household` object manages the couple's collective assets, while a `Pension` object understands its own specific tax treatment. This approach, rooted in solid object-oriented design, makes the system easier to reason about, test, and extend, as each component's boundaries are clear and logical.

* **Joyful to Use and Maintain:** The model is designed to be a pleasure to work with. For developers, this means a clean architecture, predictable behavior, and the absence of unnecessary friction. For the end-user, this translates to a tool that produces clear, reliable outputs that inspire confidence and demystify the planning process.

This planner helps couples nearing retirement to truly "think today and act for all time." It does this by modeling a sophisticated, tax-aware strategy that moves beyond simplistic, myopic goals. Instead of just minimizing the current year's tax bill, it balances immediate spending needs with long-term financial well-being by making strategic decisions—like proactive Roth conversions—designed to reduce lifetime tax liability and preserve wealth for the future.

## Service API (MVP)

Use `PlanService.run(params)` to get versioned JSON for single- or multi-year runs. Schema version: `0.1.0`.

- Single year: omit `years` or set to 1.
- Multi year: set `years > 1` and optionally pass multiple strategies.

Minimal example:

```ruby
require_relative './foresight'
include Foresight

params = {
	members: [
		{ name: 'Alice', date_of_birth: '1961-06-15' },
		{ name: 'Bob',   date_of_birth: '1967-02-10' }
	],
	accounts: [
		{ type: 'TraditionalIRA', owner: 'Alice', balance: 100_000.0 },
		{ type: 'RothIRA',        owner: 'Alice', balance: 50_000.0 },
		{ type: 'TaxableBrokerage', owners: ['Alice','Bob'], balance: 20_000.0, cost_basis_fraction: 0.7 }
	],
	income_sources: [
		{ type: 'SocialSecurityBenefit', recipient: 'Alice', start_year: 2025, pia_annual: 24_000.0, cola_rate: 0.0 },
		{ type: 'SocialSecurityBenefit', recipient: 'Bob',   start_year: 2030, pia_annual: 24_000.0, cola_rate: 0.0 }
	],
	target_spending_after_tax: 60_000.0,
	desired_tax_bracket_ceiling: 94_300.0,
	start_year: 2025,
	years: 5,
	inflation_rate: 0.02,
	growth_assumptions: { traditional_ira: 0.02, roth_ira: 0.03, taxable: 0.01 },
	strategies: [ { key: 'none' }, { key: 'bracket_fill', params: { cushion_ratio: 0.05 } } ]
}

puts PlanService.run(params)
```

JSON contains:
- `inputs`: members, accounts (with starting_balance), income_sources, growth, inflation, strategies
- `results`: per strategy `aggregate` and `yearly` rows
- `phases`: planning phases with metrics

MVP adds an `all_in_tax` metric (federal + capital gains + NY state + IRMAA Part B) per year and cumulative in aggregates.

Notes: taxes/thresholds simplified; IRMAA Part D not modeled; no inflation of tax parameters yet.