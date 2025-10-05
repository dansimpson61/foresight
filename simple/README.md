# Simple Foresight: An Ode to Joy

This application is a radical act of simplification, guided by our "Ode to Joy" development philosophy. It is an exercise in delivering 100% of the required capability in the most beautiful, clear, and minimal package possible.

## Core Purpose

The application answers one fundamental question for a user contemplating their financial future:

**"What is the long-term financial impact of strategically converting my Traditional IRA to a Roth IRA versus doing nothing?"**

## Core Capabilities

To fulfill this purpose, the application will:

1.  **Simulate two scenarios** over a 30-year horizon:
    *   A "Do Nothing" baseline.
    *   A "Fill to the Top of a Tax Bracket" strategy.
2.  **Calculate key financial outcomes** for each scenario, including lifetime taxes paid and the final composition of assets.
3.  **Present a clear, compelling visualization** that allows the user to immediately understand the trade-offs and consequences of their choice.

## Liberating Constraints

We achieve simplicity and joy through these constraints:

1.  **Single Purpose:** The application is built for a single, predefined financial profile. All data is hardcoded.
2.  **Minimalism:** We use the absolute minimum number of files, classes, and abstractions required. Simplicity is our love language.
3.  **Focus:** We only implement the two core strategies.
4.  **Immutable Stack:** We use Sinatra, Slim, and a light touch of Stimulus.

## View and Asset Structure

The UI is organized for clarity and small, composable files:

- Views
    - `views/index.slim` — Top-level page, links stylesheet and renders partials.
    - `views/diagrams.slim` — Mermaid/Markdown viewer for docs/Object_Hierarchy.md.
    - `views/partials/` — Page sections extracted into focused partials:
        - `_profile_editor.slim` — Profile editor with accordion.
        - `_simulation_editor.slim` — Simulation settings and growth assumptions.
        - `_limitations_note.slim` — Tax simplifications notice.
        - `_results_grid.slim` — Summary cards for scenarios.
        - `_viz_controls.slim` — Visualization mode toggle + badge.
        - `_chart_visualization.slim` — Income/tax chart and table.
        - `_flows_panel.slim` — Per-year flows debug panel.
        - `_net_worth_chart.slim` — Ending net worth by account type (chart).
        - `_data_scripts.slim` — Embeds results/profile as JSON for JS.
        - `_scripts.slim` — Chart.js + Stimulus controllers and bootstrap.

- Public assets
    - `public/css/app.css` — All UI styles (extracted from old inline styles).
    - `public/js/` — Stimulus controllers and bootstrap (`application.js`).
    - `public/favicon.svg` — Favicon.

Conventions:
- Partials are rendered from `index.slim` with explicit locals, e.g.
    `== render :slim, :'partials/_results_grid', locals: { do_nothing_results: ..., fill_bracket_results: ... }`
- Asset paths use `request.script_name` to work when mounted under a sub-path.