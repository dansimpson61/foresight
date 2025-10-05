# Medium-Distance Plan: Simple App Evolution

Checklist (tick as we go)
- [ ] Phase 0: Asset audit (docs + tests)
- [ ] Phase 1: Flow base + RMD/Conversion flows
- [ ] Phase 2: Extract TaxPolicy
- [ ] Phase 3: Extract WithdrawalPolicy
- [ ] Phase 4: Decisions (FillToBracket)
- [ ] Phase 5: Social Security flow + claiming decision
- [ ] Phase 6: Docs refresh

This plan guides a careful, incremental evolution to the Asset / Flow (behavioral) / Decision (value-driven) -> Simulation model. We proceed in small, test-backed steps, documenting and committing as we go.

## Phase 0 — Asset Audit (foundation first)

Goal: Ensure current Asset classes are cohesive, intention-revealing, and aligned with where we’re headed.

Scope (files):
- `simple/lib/asset.rb`
- `simple/lib/traditional_ira.rb`
- `simple/lib/roth_ira.rb`
- `simple/lib/taxable_account.rb`

Activities:
- Read through each class and confirm the minimal contract:
  - Common: balance, owner, taxability; grow(rate), withdraw(amount), deposit(amount)
  - tax_on_withdrawal(amount) returns clear tax character breakdown
  - TraditionalIRA: rmd_required?(age), calculate_rmd(age)
  - TaxableAccount: cost_basis_fraction behavior clear and documented
- Add or tighten docstrings (1–2 lines) for each public method.
- Add 2–3 minimal unit tests per asset type under `simple/spec/` (happy path + edge case).
- Commit: "Phase 0: Asset audit, docs, and tests (no behavior change)"

Acceptance:
- Tests green; code reads like prose; no public behavior changed.

## Phase 1 — Introduce Flow base and two concrete flows

Goal: Create the smallest behavioral flow layer to express existing logic without changing outputs.

Scope:
- New: `simple/lib/flows/flow.rb` (abstract), `simple/lib/flows/rmd_flow.rb`, `simple/lib/flows/conversion_flow.rb`
- Light touches to `simple/app.rb` (Simulator) to instantiate/apply flows internally but keep the public JSON unchanged.

Activities:
- Implement Flow contract:
  - amount, tax_character(), apply(accounts)
- RMDFlow: produces ordinary income, reduces Traditional IRA
- ConversionFlow: Traditional -> Roth, ordinary income
- In Simulator, replace inline RMD and conversion mutations with flow creation + apply(); keep tax math and aggregates unchanged.
- Add a per-year tracing hook: collect `flows_applied` entries with `{ type, amount, tax_character, participants }` for observability and future UI auditing. This is additive-only and does not change existing fields. A minimal UI panel renders these flows per year for both strategies.
- Add minimal unit tests for the two flows and an integration test asserting the same aggregate results as before for one profile.
- Commit in two steps:
  - "Phase 1a: Add Flow base + RMD/Conversion flows with tests"
  - "Phase 1b: Simulator uses flows internally (outputs unchanged)"

Acceptance:
- Snapshot test: previous vs new aggregates identical for default profile.
- UI smoke: editors open/close; table toggles; flows panel toggles. Stimulus bootstrap has a tiny inline fallback for reliability.

## Phase 2 — Extract TaxPolicy (pure helper)

Goal: Make tax logic explicit and intention-revealing without changing results.

Scope:
- New: `simple/lib/policies/tax_policy.rb`
- Minimal changes in Simulator to call TaxPolicy methods.

Activities:
- Move existing logic to:
  - ordinary_tax(ordinary_income)
  - capital_gains_tax(cg_amount, ordinary_income)
  - taxable_social_security(provisional_income, ss_total)
- Keep YAML brackets source and shape unchanged; add one small comment linking to `tax_brackets.yml`.
- Add unit tests for TaxPolicy with representative bracket edges.
- Commit: "Phase 2: Extract TaxPolicy; tests; no public change"

Acceptance:
- All tests green; integration results remain identical.

## Phase 3 — Introduce WithdrawalPolicy (pure helper)

Goal: Encapsulate withdrawal order; keep behavior consistent.

Scope:
- New: `simple/lib/policies/withdrawal_policy.rb`
- Simulator uses it for spending withdrawals; still returns the same JSON shape.

Activities:
- Implement withdraw_for_spending(amount, accounts) -> [WithdrawalFlow]
- Cover taxable basis logic as it exists; keep it simple and documented.
- Unit tests: minimal cases (exact match, partial coverage across assets).
- Commit: "Phase 3: Add WithdrawalPolicy; align Simulator; tests; no public change"

Acceptance:
- No observable behavior changes; tests pass.

## Phase 4 — Decisions as value-driven strategies

Goal: Separate value judgments from mechanics. The simulator queries decisions to propose flows.

Scope:
- New: `simple/lib/decisions/decision_policy.rb` (interface), `simple/lib/decisions/fill_to_bracket_decision.rb`
- Simulator composes a list of decisions (start with one).

Activities:
- Implement decide_for_year(context) -> [Flow] for FillToBracketDecision.
- Replace inline conversion headroom logic with the decision; keep semantics the same.
- Unit tests: decision returns a ConversionFlow with expected amount under representative scenarios (enough headroom, zero headroom, small traditional balance).
- Commit: "Phase 4: Add Decisions; FillToBracketDecision; tests; outputs unchanged"

Acceptance:
- Results unchanged; decision logic is pure and test-covered.

## Phase 5 — Social Security as an explicit flow with a claiming decision

Goal: Respect SS rules explicitly while remaining minimal.

Scope:
- New: `simple/lib/flows/social_security_flow.rb`, `simple/lib/decisions/claim_ss_decision.rb`
- Simulator uses the decision to emit SS flows each year once claimed.

Activities:
- SocialSecurityFlow: income-only flow with :social_security character
- ClaimSSDecision: initial version may simply claim at profile’s configured age; later variants can be plugged in
- Ensure TaxPolicy computes taxable portion; flows simply signal type
- Tests: basic claiming boundaries, taxable portion integration remains correct
- Commit: "Phase 5: SS flow + claiming decision; tests; no public change"

Acceptance:
- Same outputs as before; code clearer.

## Phase 6 — Public documentation and example diffs

Goal: Make the model discoverable and the benefits visible.

Scope:
- Update `docs/Object_Hierarchy.md` with the final shape and tiny examples.
- Add a short section to `docs/AI_Agent_Onboarding.md` linking to flows/decisions.

Activities:
- One small diagram snippet: year-in-the-life flow sequence
- A short blurb in onboarding about where to add new Flow/Decision
- Commit: "Phase 6: Docs refresh for Flows/Decisions"

Acceptance:
- Docs reflect reality; contributors know where to extend.

---

## cadence: tiny increments, tests, docs, commits

For each phase (and sub-step):
- Write/adjust minimal tests first (1 happy path + 1 edge case).
- Implement the smallest change to make tests pass.
- Update a brief inline comment or a single doc bullet if behavior or intent becomes clearer.
- Commit with a precise message (see above).
- Run integration check comparing aggregate outputs to ensure no unintended drift.

Optional guard-rails:
- Add a simple snapshot JSON for the default profile to detect accidental changes.
- Keep PRs < ~200 lines when possible; prioritize legibility.

## risks and mitigations

- Scope creep: avoid adding flows until rules differ materially.
- Hidden coupling: keep decisions pure; flows apply changes; simulator orchestrates only.
- Test brittleness: test behavior (contract), not internal steps; use small, clear assertions.

## success criteria

- Simulator code shrinks; responsibilities are clearer.
- Tests are green throughout; outputs stay stable across phases.
- New strategies (decisions) and flows are easy to add in a day.
- Documentation is short, accurate, and helpful.
