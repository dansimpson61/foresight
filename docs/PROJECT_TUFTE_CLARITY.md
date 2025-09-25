# Project Tufte's Clarity

This document outlines a two-part architectural evolution for the Foresight application, designed to enhance clarity, testability, and the overall joy of development, in full alignment with our "Ode to Joy" philosophy.

## Part 1: Refactor the Domain Model with Voluntary vs. Involuntary Events

*   **The "Why" (Ode to Joy):** This change brings profound clarity to our core logic. By distinguishing between events that *happen to you* (involuntary) and choices you *make* (voluntary), we make the `PlanService`'s purpose—comparing a "Do Nothing Baseline" to a "Strategy"—explicit in the code. This simplifies algorithms, improves testability, and makes our domain model a more faithful representation of the real world.

*   **Proposed Steps:**
    1.  **Introduce a `Voluntary` Mixin:** Create a simple marker module (`module Foresight::Voluntary; end`) to identify strategic actions.
    2.  **Tag Voluntary Events:** Include this module in classes that represent strategic choices, starting with `Foresight::FinancialEvent::RothConversion`.
    3.  **Refactor `PlanService`:** Update the service to first calculate the baseline plan using only involuntary events. Then, for each strategy, layer the voluntary events on top. This creates a clean, logical separation between the two scenarios.
    4.  **Revive the "Sweet Spot" Spec:** Uncomment and refactor the `plan_service_scenario_spec.rb`. This spec will become the definitive, high-level test that proves our core logic correctly distinguishes between baseline and strategy, especially concerning Roth conversions in the low-income years between retirement and Social Security.

## Part 2: Implement a Ruby Chart Class Hierarchy

*   **The "Why" (Ode to Joy):** This architectural improvement champions an "exquisite data flow." It establishes a clean separation of concerns between raw financial calculation and data preparation for visualization. It makes our data transformations for charts rigorously testable on the server side, simplifies our API endpoints, and provides a clear, stable contract for the frontend, perfectly aligning with the goals in `FRONTEND_PLAN.md`.

*   **Proposed Steps:**
    1.  **Create a `BaseChart` Class:** Establish a parent class in `models/charts/` that accepts a `PlanService` result and defines a common interface for generating chart-ready JSON.
    2.  **Implement Concrete Chart Subclasses:** Build specific classes like `TaxBracketChart` and `IrmaaChart`. Each class will be responsible for transforming the plan data into the precise structure required for a specific visualization. All the complex data-munging logic lives here.
    3.  **Add Rigorous Unit Tests:** For each chart class, create a corresponding spec. These tests will feed the class a sample plan result and assert that the JSON output is perfectly formed. This guarantees our charts are not just pretty, but provably correct.
    4.  **Simplify the API Endpoint:** Refactor the `/api/plan` endpoint. Its new, simpler job will be to run the `PlanService`, pass the results to our new Chart objects, and serialize their output into a clean JSON response for the Stimulus controllers.
