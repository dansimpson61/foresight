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
2.  **Run the application:**
    ```bash
    bundle exec rackup --port 9292
    ```
3.  **Open the UI:**
    Navigate to `http://127.0.0.1:9292/ui` in your browser.

## Key Endpoints

*   `GET /ui`: The primary user interface for running simulations.
*   `POST /plan`: The API endpoint that runs a plan and returns JSON data.
*   `GET /plan/example`: Returns a sample JSON payload for testing and demos.
*   `GET /strategies`: Lists the available Roth conversion strategies.

## Project Status

The project is under active development. The latest version is **0.1.1**. See the [`CHANGELOG.md`](./CHANGELOG.md) for a detailed history of changes.
