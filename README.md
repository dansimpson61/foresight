# Foresight: A Joyful Retirement Planner

Clarity in, clarity out. Foresight is a retirement planning tool designed for insight, not just numbers. It helps visualize and compare the long-term impact of financial strategies, with a focus on Roth conversions, tax efficiency, and portfolio sustainability.

This project is an exercise in craftsmanship, developed according to the "Ode to Joy" development philosophy. It aims to be a tool that is not only functional but also elegant, insightful, and a pleasure to use and maintain.

## Guiding Principles

Our development is guided by a few core tenets rooted in our [Ode to Joy](Ode%20to%20Joy%20-%20Ruby%20and%20Sinatra.txt):

*   **Clarity and Expressiveness:** The code should read like well-written prose. In a domain as complex as tax planning, the code itself must serve as documentation, making the underlying financial logic transparent.
*   **Focused Purpose:** Each class and method has a single, well-defined responsibility that directly reflects a real-world financial concept. This solid, object-oriented design makes the system easier to reason about, test, and extend.
*   **Data as the Hero:** Inspired by the work of Edward Tufte, the interface is minimalist, responsive, and intuitive. We maximize the data-ink ratio, eliminating chartjunk to present complex information with precision and legibility.

For a deeper dive into our design philosophy and data model, please see the documents in the [`/docs`](./docs/) folder.

## Features

Foresight provides a suite of visualizations and data tables to facilitate clear-headed scenario comparison:

*   **Lifetime Asset Progression:** A stacked area chart showing the growth and composition of your Taxable, Traditional, and Roth accounts over time.
*   **Annual Tax Liability Overlay:** A thin line chart overlaid on your assets, clearly showing the annual tax cost of your chosen strategy.
*   **IRMAA Impact Timeline:** A color-coded timeline that instantly shows whether your income will trigger Medicare premium surcharges in future years.
*   **Tax-Efficiency Gauge:** A simple bar chart comparing the tax-free (Roth) vs. tax-deferred (Traditional) composition of your portfolio at the end of the plan.
*   **Detailed Data Table:** A year-by-year breakdown of over 20 key metrics, including income sources, taxes, conversions, withdrawals, and ending balances.

## Tech Stack

Foresight is proudly built with a minimalist, joyful stack:

*   **Backend:** Ruby & Sinatra
*   **Frontend:** Slim templates with a light sprinkling of StimulusJS
*   **Visualizations:** Pure SVG, no heavy charting libraries

## Getting Started

1.  **Install dependencies:**
    ```bash
    bundle install
    ```
2.  **Run (choose one):**
        - Main app only (classic UI):
            ```bash
            bin/dev-main
            ```
            Open: `http://127.0.0.1:9292/ui`

        - Simple app only (radically simplified UI):
            ```bash
            bin/dev-simple
            ```
            Open: `http://127.0.0.1:9393/`

        - Both apps in one server (URL mapped):
            ```bash
            bin/dev-both
            ```
            Open: `http://127.0.0.1:9292/` for a landing page with links to both UIs
            - Classic: `http://127.0.0.1:9292/ui`
            - Simple: `http://127.0.0.1:9292/simple/`

### For AI contributors

If you’re an AI agent contributing to this repo, please start with the onboarding guide and quick checklist:

- docs/AI_Agent_Onboarding.md
- docs/AI_Agent_Checklist.md

## Key Endpoints

*   `GET /ui`: The primary user interface for running simulations.
*   `POST /plan`: The API endpoint that runs a plan and returns JSON data.
*   `GET /plan/example`: Returns a sample JSON payload for testing and demos.
*   `GET /strategies`: Lists the available Roth conversion strategies.

### Simple App Endpoints (when running simple app)

*   `GET /` (under `/simple` when using the combined server): Simple UI landing page
*   `POST /run`: Runs the simplified simulation with the posted profile JSON

## Project Status

The project is under active development. See the [`CHANGELOG.md`](./CHANGELOG.md) for a detailed history of changes.

## Architecture notes: running both and future extraction

- The classic app mounts `Foresight::API` and `Foresight::UI` in `app.rb`.
- The simplified app is a modular Sinatra app: `Foresight::Simple::UI` in `simple/app.rb`.
- `config.multi.ru` uses `Rack::URLMap` to serve both at once: `/` (main) and `/simple`.

To extract either app later:
- Simple app can be copied as a standalone Rack app using `simple/config.ru`.
- Main app remains standalone via `config.ru` at the repo root.

## Namaste

- Focus on the 'simple' app. Understand the parent ''foresight' app to be well-intentioned but poorly executed, too complex, too heavy, too convuluted. The parent app is a model and a cautionary tale, a beloved ancestor from whom we can learn but whom we must not emulate or imitate, a truly loving parent who wants us to be better in every way. Do not hesitate to ask questions if you struggle to understand anything.

- Be simple. Be as good as bread.
  