# Simple App – Object Hierarchy (Current vs Desired)

Edit this file freely. The diagrams are Mermaid, so they’re just text.

Tip: In VS Code or GitHub, Mermaid renders automatically. To change nodes or relations, edit the class names or arrows below.

---

## 1) Current state (reflects code today)

Assumptions: names shortened for readability. All classes live under the Ruby module `Foresight::Simple` unless otherwise noted.

```mermaid
classDiagram
	direction TB

	class UI {
		+GET "/" (renders index.slim)
		+POST "/run" (returns JSON)
		-run_simulation(strategy, params, profile)
		+format_currency(number)
	}

	class Simulator {
		+run(strategy, strategy_params, profile) : Results
		.. private helpers ..
		-get_tax_brackets_for_year(year)
		-determine_conversion_events(...)
		-withdraw_for_spending(...)
		-perform_roth_conversion(amount, accounts)
		-calculate_taxes(ordinary_income, capital_gains, brackets)
		-calculate_taxable_social_security(provisional, ss_total, brackets)
		-grow_assets(accounts, growth)
		-get_age(dob, year)
		-aggregate_results(yearly)
	}

	class Asset {
		+balance
		+owner
		+taxability
		+grow(rate)
		+withdraw(amount)
		+deposit(amount)
		+tax_on_withdrawal(amount)~abstract~
	}

	class TraditionalIRA {
		+tax_on_withdrawal(amount)
		+rmd_required?(age)
		+calculate_rmd(age)
	}

	class RothIRA {
		+tax_on_withdrawal(amount)
		+rmd_required?(age) = false
	}

	class TaxableAccount {
		+cost_basis_fraction
		+tax_on_withdrawal(amount)
		+generate_dividends(yield_rate)
	}

	class ProfileYAML {
		profile.yml
	}

	class TaxBracketsYAML {
		tax_brackets.yml
	}

	UI --> Simulator : uses
	Simulator --> TraditionalIRA : instantiates
	Simulator --> RothIRA : instantiates
	Simulator --> TaxableAccount : instantiates
	TraditionalIRA --|> Asset
	RothIRA --|> Asset
	TaxableAccount --|> Asset
	Simulator --> TaxBracketsYAML : reads
	Simulator --> ProfileYAML : reads defaults
```

Notes
- Routes live in `simple/app.rb` within `class UI < Sinatra::Base`.
- Domain objects live in `simple/lib/`.
- Data lives in `simple/profile.yml` and `simple/tax_brackets.yml`.

---

## 2) Desired state (Assets, Flows-with-Behavior, Decisions)

Goal: Keep everything joyful and minimal while acknowledging that flows have distinct rules and that decisions encode human values. No heavy frameworks. No speculative abstractions.

Changes from current:
- Keep `UI` and `Asset` classes as-is.
- Keep a single `Simulator`, but extract tiny, explicit helpers:
	- `TaxPolicy` (per-year brackets and SS thresholds; intention-revealing tax math)
	- `WithdrawalPolicy` (encapsulates withdrawal order logic)
- Model “Flows” as small behavioral objects (not plain structs): RMD, SocialSecurity, Withdrawal, Conversion, Tax. Each provides its own tax character and validation rules.
- Model “Decisions” (aka Actions/Strategies) as value-driven policies that propose flows, not mutate state directly.

```mermaid
classDiagram
	direction TB

	class UI {
		+GET "/"
		+POST "/run"
	}

	class Simulator {
		+run(strategy, strategy_params, profile) : Results
		-build_accounts(profile)
		-compute_year(profile, taxPolicy, withdrawalPolicy, decisions)
	}

	class TaxPolicy {
		+for_year(year)
		+ordinary_tax(ordinary_income) : number
		+capital_gains_tax(cg_amount, ordinary_income) : number
		+taxable_social_security(provisional_income, ss_total) : number
	}

	class WithdrawalPolicy {
		+withdraw_for_spending(amount, accounts) : Flow[]
		note "Order: Taxable -> Traditional -> Roth"
	}

	%% Flows with behavior
	class Flow {
		<<abstract>>
		+apply(accounts) : void
		+tax_character() : Symbol
		+amount : number
	}
	class RMDFlow {
		+tax_character() = :ordinary
		+apply(accounts) : reduces Traditional, emits income
	}
	class SocialSecurityFlow {
		+tax_character() = :social_security
		+apply(accounts) : none (income only)
	}
	class WithdrawalFlow {
		+tax_character() = :ordinary|:capital_gains
		+apply(accounts) : pulls from source asset
	}
	class ConversionFlow {
		+tax_character() = :ordinary
		+apply(accounts) : Traditional -> Roth transfer
	}
	class TaxFlow {
		+tax_character() = :nontaxable
		+apply(accounts) : reduces cash/taxable pool
	}

	Flow <|-- RMDFlow
	Flow <|-- SocialSecurityFlow
	Flow <|-- WithdrawalFlow
	Flow <|-- ConversionFlow
	Flow <|-- TaxFlow

	%% Decisions (value-driven)
	class DecisionPolicy {
		<<interface>>
		+decide_for_year(context) : Flow[]
	}
	class FillToBracketDecision {
		+decide_for_year(context) : [ConversionFlow]
	}
	class ClaimSSDecision {
		+decide_for_year(context) : [SocialSecurityFlow]
	}

	class Asset {
		+grow(rate)
		+withdraw(amount)
		+deposit(amount)
		+tax_on_withdrawal(amount)
	}
	class TraditionalIRA
	class RothIRA
	class TaxableAccount

	UI --> Simulator : uses
	Simulator --> TaxPolicy : uses brackets
	Simulator --> WithdrawalPolicy : uses for spending
	Simulator --> Flow : creates & applies
	Simulator --> DecisionPolicy : queries for value-driven flows
	Simulator --> TraditionalIRA : instantiates
	Simulator --> RothIRA : instantiates
	Simulator --> TaxableAccount : instantiates
	TraditionalIRA --|> Asset
	RothIRA --|> Asset
	TaxableAccount --|> Asset
```

Guardrails (to avoid the parent app’s complexity)
- Add a Flow subtype only when rules differ materially (e.g., RMD vs Conversion).
- Decisions must be pure: propose flows; the simulator applies them.
- Keep each Flow tiny: tax_character and apply(accounts) should be obvious and short.
- Keep files short and names intention-revealing.
- Avoid global state; pass explicit context.

---

### How to edit these diagrams
- Change class names, methods, or relations in the Mermaid blocks above.
- Common Mermaid arrows:
	- `A --|> B` inheritance
	- `A --> B` usage/association
	- `A ..|> B` interface implementation
- Keep it small and readable; this chart should fit in one screen.

