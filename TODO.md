## Foresight: Strategic TODO

This document outlines the strategic steps to evolve Foresight from a financial calculator into an insight engine, in alignment with our "Ode to Joy" philosophy and design documents.

### Phase 1: Build the Analytical Core

The highest priority is to build the multi-scenario analysis engine. The tool cannot provide insight until it can compare different choices.

-   [ ] **Refactor `PlanService` to be a `ScenarioAnalysisService`**:
    -   [ ] Modify its main method to run multiple simulations for each year to find the optimal Roth conversion amount.
    -   [ ] The service should take a `Strategy` object as input (e.g., `strategy.conversion_target = "fill_22_percent_bracket"` and `strategy.conversion_ceiling = "avoid_irmaa_tier_1"`).
-   [ ] **Implement IRMAA Surcharge Calculations**: The core analysis is impossible without this. The cliffs are the dragons we are here to slay. Add IRMAA logic to the `TaxYear` model based on the MAGI calculation.
-   [ ] **Implement RMD (Required Minimum Distribution) Calculations**: This is essential for long-term accuracy. RMDs are a primary driver of late-in-life tax burdens that we aim to mitigate.
-   [ ] **Enhance API Response (`/plan` endpoint)`**:
    -   [ ] Structure the JSON response to clearly separate the "with strategy" and "baseline (do nothing)" scenarios.
    -   [ ] Add a top-level `summary` object with key insights (e.g., total taxes saved, change in final portfolio value).
    -   [ ] Add a `recommended_actions` array with a year-by-year plan.

### Phase 2: Create an Insightful User Interface

With a powerful analytical engine, the next step is to translate its output into a user experience that provides clarity and confidence.

-   [ ] **Develop Key Visualizations**:
    -   [ ] Implement `tax_efficiency_chart.js` to show a side-by-side comparison of annual taxable income ("strategy" vs. "baseline"). This is the most important chart.
    -   [ ] Implement `irmaa_chart.js` to visualize how the strategy successfully navigates the income cliffs.
-   [ ] **Build the Action-Oriented Summary View**:
    -   [ ] The main view should display the high-level summary (`summary` object from the API) in clear, plain language.
    -   [ ] Display the `recommended_actions` as a clear, step-by-step timeline.
-   [ ] **Create the Interactive Controls**:
    -   [ ] Implement the `tax_bracket_slider_controller.js` to allow the user to change the `Strategy` parameters (e.g., "What if I only convert up to the 12% bracket?") and re-run the analysis on the fly without a page reload.

### Phase 3: Refine and Deepen the Model

Once the core insight loop is complete, we can add more nuance and accuracy.

-   [ ] **Model Social Security Claiming Strategies**: Add functionality to model starting Social Security at different ages to see how it impacts the "low-income window" available for Roth conversions.
-   [ ] **Implement Smart Withdrawal Strategy**: Code the withdrawal logic (Taxable -> Traditional -> Roth) into the annual simulation for retirement years.
-   [ ] **Account for State Taxes**: Add a field for state tax rates to provide a more complete picture of total tax liability.

This strategic TODO provides a roadmap. By focusing on the analytical core first, we ensure that we have something genuinely valuable to present in the UI. This approach directly serves the "Ode to Joy" by building a tool that is not just functional, but truly insightful.