# AI Agent Onboarding for Foresight

Welcome! This guide orients AI coding agents to contribute joyfully and effectively. It focuses on three anchors:

- The Ode to Joy development philosophy (root: `Ode to Joy - Ruby and Sinatra.txt`)
- High-level intent docs (folder: `docs/`)
- The radically simplified embedded app (folder: `simple/`)

Keep changes small, intention-revealing, and delightful to read and maintain.

## North Star: Ode to Joy

Build software that is technically sound, human-centered, and aesthetically facilitative and pleasing. That means:

- Clarity and POLA: Code reads like prose and behaves as expected.
- Dry: For every thing, there is one thing. There is one source of truth.
- Minimalism: Prefer the least code that cleanly solves the problem. The best JavaScript is the least JavaScript.
- Cohesion: Small, focused classes/methods; avoid needless abstractions.
- Object-oriented: Encapsulated, self-knowing objects expose only what they choose to expose and only on their own terms.
- Polymorphism: Objects clearly and simply adapt to their context, expressing flexible behaviors rooted in a single source of truth—inviting reuse and delight, never surprise.
- Tests as confidence: A tiny, readable test is better than a comment.
- Joyful ergonomics: Thoughtful naming, graceful error handling, concise logs.

Reference: `Ode to Joy - Ruby and Sinatra.txt` (root).

## What “Foresight” is, at a glance

- Purpose: Provide insight into long-term tax/retirement outcomes, especially Roth conversions and tax efficiency.
- Design: Tufte-inspired clarity—data forward, minimal chrome, no chart junk.
- Architecture: Minimal Sinatra apps. The simple app is your primary playground for contributions.

For intent and design details, see `docs/`:
- `Domain_Model.md` (domain concepts)
- `PROJECT_TUFTE_CLARITY.md` (visual design philosophy)
- `FRONTEND_PLAN.md` and `UX-UI Design Spec.md` (UI intent)
- `Testing_Strategy.md` and `capybara_for_nix.md` (where relevant)

## Start here: the simple app

Use the simple app as the reference implementation and the safest surface for incremental value.

Key files and layout:
- `simple/app.rb` — modular Sinatra app mounting routes:
  - GET `/` renders `simple/views/index.slim` with two scenarios (do nothing, fill-to-bracket)
  - POST `/run` accepts a profile and optional strategy, returns results JSON
- `simple/views/index.slim` — Slim template, Chart.js via CDN, a light touch of Stimulus controllers
- `simple/lib/*.rb` — tiny, intention-revealing domain objects: `Asset`, `TraditionalIRA`, `RothIRA`, `TaxableAccount`
- `simple/profile.yml` — default profile (members, accounts, expenses, assumptions)
- `simple/tax_brackets.yml` — simplified bracket data by year
- `simple/spec/simulator_spec.rb` — Minitest specs for the simulation engine
- `simple/config.ru` — rack entry for standalone serving

How to run (fish shell):

- Simple app only
  ```fish
  # from repo root
  bundle install
  bin/dev-simple
  # open http://127.0.0.1:9393/
  ```

- Both classic and simple apps
  ```fish
  bundle install
  bin/dev-both
  # open http://127.0.0.1:9292/ (landing)
  # classic: http://127.0.0.1:9292/ui
  # simple:  http://127.0.0.1:9292/simple/
  ```

- Simple app via rackup directly
  ```fish
  bundle install
  bundle exec rackup simple/config.ru --port 9393
  ```

## API contract (simple app)

- POST `/run`
  - Input JSON shape (symbolize-able keys):
    - `profile` (object) — same shape as `simple/profile.yml`
    - `strategy` (string) — "do_nothing" | "fill_to_bracket" (defaults to `fill_to_bracket`)
    - `strategy_params` (object) — e.g., `{ "ceiling": 94300 }`
  - Output JSON:
    - `do_nothing_results` — `{ yearly: [...], aggregate: { ... } }`
    - `fill_bracket_results` — same shape
    - `profile` — echo of effective profile

Notes:
- Ordinary income, capital gains, SS taxation, and RMDs are simplified.
- Strategy `fill_to_bracket` converts up to a target taxable-ordinary ceiling.

## Contribution style for AI agents

- Keep it tiny: One cohesive improvement per PR.
- Prefer edits to `simple/` unless a change must touch the main app.
- Respect the minimal stack: Ruby, Sinatra, Slim, light Stimulus, Chart.js CDN. No new heavy dependencies.
- Name with care: Reveal intent; avoid abbreviations and cleverness.
- Logs and messages: Use plain, actionable language; be concise by default.
- Avoid speculative abstraction: Refactor only when two concrete uses emerge.

## Tests first, then code

- Add or update a minimal Minitest spec under `simple/spec/` that proves value.
- Cover one happy path plus one edge case when reasonable.
- Run tests locally:
  ```fish
  bundle exec ruby simple/spec/simulator_spec.rb
  ```

## Safety, clarity, and security

- No secrets in code or logs. No external calls unless explicitly required.
- Validate params and fail gracefully with clear messages.
- Prefer explicit, small data shapes; avoid global mutable state.
- Keep front-end JS minimal; favor server-side rendering.

## Good first AI tasks (simple app)

- Tighten tax calculation clarity: inline comments, small helper extractions that improve readability without changing behavior.
- Expand tests in `simple/spec/simulator_spec.rb` to lock in current behavior for one additional edge case (e.g., zero-SS scenario).
- Add a minimal JSON example in `simple/README.md` demonstrating POST `/run` payload and response outline.
- Improve `index.slim` discoverability: a short, unobtrusive note near the table toggle or unit labels where helpful.

Each should be a self-contained PR with before/after justification in the description.

## Acceptance criteria per change

- Upholds Ode to Joy principles (clarity, minimalism, POLA).
- Adds or updates a tiny test (when behavior changes or needs locking).
- Keeps dependencies unchanged unless absolutely necessary.
- Docs updated when a public behavior changes (README or inline comments).

## Quick Reference: files to know

- Philosophy: `Ode to Joy - Ruby and Sinatra.txt`
- Intent: `docs/Domain_Model.md`, `docs/PROJECT_TUFTE_CLARITY.md`, `docs/FRONTEND_PLAN.md`
- Simple app entry: `simple/app.rb`, `simple/config.ru`
- Simple app UI: `simple/views/index.slim`
- Domain objects: `simple/lib/*.rb`
- Data sources: `simple/profile.yml`, `simple/tax_brackets.yml`
- Tests: `simple/spec/simulator_spec.rb`

## PR checklist (short)

- The change is small and intention-revealing.
- Tests added/updated and pass locally.
- Public behavior documented where relevant.
- No unnecessary complexity; no heavy new deps.
- Code reads like well-written prose.

Thank you for keeping Foresight joyful.
