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
    +getRoot
    +postRun
    -runSimulation
    +formatCurrency
  }

  class Simulator {
    +run
    -getTaxBracketsForYear
    -determineConversionEvents
    -performRothConversion
    -growAssets
    -getAge
    -aggregateResults
  }

  class Asset {
    +balance
    +owner
    +taxability
    +grow
    +withdraw
    +deposit
    +taxOnWithdrawal
  }

  class TraditionalIRA
  class RothIRA
  class TaxableAccount

  class ProfileYAML
  class TaxBracketsYAML

  UI --> Simulator
  Simulator --> TraditionalIRA
  Simulator --> RothIRA
  Simulator --> TaxableAccount
  TraditionalIRA --|> Asset
  RothIRA --|> Asset
  TaxableAccount --|> Asset
  Simulator --> TaxBracketsYAML
  Simulator --> ProfileYAML
```

Notes
- Routes live in `simple/app.rb` within `class UI < Sinatra::Base`.
- Domain objects live in `simple/lib/`.
- Data lives in `simple/profile.yml` and `simple/tax_brackets.yml`.

---

## 2) **NOT** our Desired state (Assets, Flows-with-Behavior, Decisions) *We need to fix this.*

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
    +getRoot
    +postRun
  }

  class Simulator {
    +run
    -buildAccounts
    -computeYear
  }

  class TaxPolicy {
    +forYear
    +ordinaryTax
    +capitalGainsTax
    +taxableSocialSecurity
  }

  class WithdrawalPolicy {
    +withdrawForSpending
  }

  class Flow {
    <<abstract>>
    +apply
    +taxCharacter
    +amount
  }
  class RMDFlow
  class SocialSecurityFlow
  class SocialSecurityFlow
  class WithdrawalFlow
  class ConversionFlow
  class TaxFlow

  Flow <|-- RMDFlow
  Flow <|-- SocialSecurityFlow
  Flow <|-- WithdrawalFlow
  Flow <|-- ConversionFlow
  Flow <|-- TaxFlow

  class DecisionPolicy {
    <<interface>>
    +decideForYear
  }
  class FillToBracketDecision
  class ClaimSSDecision

  class Asset
  class TraditionalIRA
  class RothIRA
  class TaxableAccount

  UI --> Simulator
  Simulator --> TaxPolicy
  Simulator --> WithdrawalPolicy
  Simulator --> Flow
  Simulator --> DecisionPolicy
  Simulator --> TraditionalIRA
  Simulator --> RothIRA
  Simulator --> TaxableAccount
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

---

## 3) Year-in-the-life (sequence)

```mermaid
sequenceDiagram
  participant UI
  participant Simulator
  participant Policies
  participant Flows

  UI->>Simulator: run(profile, strategy)
  Simulator->>Policies: TaxPolicy(taxable SS, taxes)
  Simulator->>Flows: RMDFlow.apply()
  Simulator->>Decisions: ClaimSSDecision.decide_for_year()
  Simulator->>Flows: SocialSecurityFlow.apply()
  Simulator->>Policies: WithdrawalPolicy.withdraw_for_spending()
  Simulator->>Flows: ConversionFlow.apply() (if strategy)
  Simulator-->>UI: yearly + aggregate + flows_applied
```

