# Bug Report: Frontend Data Handling & Simulation Engine Failures

## 1. Executive Summary

This document details the investigation and resolution of a series of cascading failures that manifested as a "Frontend Data Handling" error in the UI. While the initial symptom pointed to a simple data mismatch, the root cause was a series of tangled responsibilities and data format inconsistencies between the API layer, the `PlanService`, and the `LifePlanner` simulation engine.

The resolution involved a comprehensive refactoring to establish a clear separation of concerns, resulting in a more robust, maintainable, and predictable architecture that aligns with the "Ode to Joy" philosophy of craftsmanship and clarity.

## 2. Initial Symptoms

The user consistently reported the following error in the UI:

> Error: Breakdown in 'Frontend Data Handling'
> Could not find results for the selected strategy ('do_nothing') in the data from the server.

This error indicated that the frontend JavaScript was successfully receiving a response from the backend, but the `results` object within that response did not contain the expected `"do_nothing"` key.

## 3. The Diagnostic Journey: A Tale of False Leads

Our investigation followed a winding path, with each step revealing a new layer of the problem.

### Phase 1: The Hunt for a Simple Mismatch

-   **Hypothesis:** There is a simple typo in the strategy key (e.g., `"do_nothing"` vs. `"do-nothing"`).
-   **Action:** Used `grep` to search the entire codebase for the string `"do_nothing"`.
-   **Finding:** The key was used consistently across the UI, API, and backend services. **This was a false lead.**

### Phase 2: Instrumenting the Simulation

-   **Hypothesis:** The simulation engine itself is crashing before it can generate any results.
-   **Action:** Injected `[STRATEGY_STEP]` logging tags into the `AnnualPlanner` and `ConversionStrategies`.
-   **Finding:** The server logs revealed that the simulation was indeed crashing. The logs would stop abruptly, and the server would return a `500 Internal Server Error`. This was progress, but the *reason* for the crash was still unknown.

### Phase 3: The "KeyError" Rabbit Hole

-   **Hypothesis:** The simulation is crashing due to an invalid data model.
-   **Action:** We ran the `test/smoke_plan_service.rb` script.
-   **Finding:** The smoke test failed immediately with `KeyError: key not found: :claiming_age`. This was a **critical discovery**. It proved that our internal testing tools were using an outdated data structure.
-   **Sub-Resolution:** We corrected the smoke test and fixed a series of related bugs in the models (`Household#net_worth`, `Household#rmd_for`, `Person#rmd_eligible_in?`). After this, the smoke test still failed, but with a new error.

### Phase 4: The "Implicit Conversion" & "Undefined Method" Errors

-   **Hypothesis:** There is a data format mismatch between the components of the backend.
-   **User Insight (POLA Violation):** The user correctly pointed out that a method named `to_json_report` should not return a raw Hash. This was a violation of the **Principle of Least Astonishment**.
-   **Finding:** This insight was the key. We discovered a tangled data flow:
    1.  The `LifePlanner` was incorrectly converting its results to a JSON string.
    2.  The `PlanService` was then incorrectly trying to parse this string *again*, leading to `TypeError: no implicit conversion of Hash into String`.
    3.  When we corrected this, it exposed a new error: `undefined method 'key?' for an instance of String`, which was caused by the `PlanService` incorrectly passing strategy *names* (Strings) instead of strategy *objects* to the `LifePlanner`.

## 4. The Root Cause: A Tangled Separation of Concerns

The core problem was a failure to adhere to the principle of **Separation of Concerns**. Each component was trying to do part of the other's job:

-   The `LifePlanner` (the simulation engine) was wrongly concerned with **JSON formatting**.
-   The `PlanService` (the orchestrator) was wrongly trying to **re-parse data** it should have received as a pure Ruby object.
-   The `API` layer (the web interface) was not correctly **validating the data type** it received from the `PlanService`.

This tangled responsibility created a brittle and unpredictable system where fixing one bug would immediately reveal another.

## 5. The Definitive Solution: Clarity and Craftsmanship

The final solution was a comprehensive refactoring to establish a clear, linear, and honest data flow that aligns with our "Ode to Joy" philosophy.

1.  **The `LifePlanner` is the Engine.**
    -   Its *only* job is to run the simulation.
    -   It now returns a pure, raw **Ruby Hash** of results.
    -   Its primary method has been honestly renamed to `build_report`.

2.  **The `PlanService` is the Orchestrator.**
    -   It receives the raw **Hash** from the `LifePlanner`.
    -   It assembles the final report structure, wrapping it in our schema version and mode.
    -   As its final step, it **converts the report to a JSON string**, preparing it for the web.

3.  **The `API` is the Interface.**
    -   It receives the JSON **string** from the `PlanService`.
    -   It **parses the string into a Hash** so it can be validated by the `ContractValidator`.
    -   It takes the validated **Hash** and re-encodes it into the final JSON response, wrapped in our metadata envelope, for the browser.

This new architecture is more robust, easier to debug, and honors the principle that each component should do one thing and do it well. The successful run of the smoke test and the final, successful execution of the application in the UI are the definitive proof of this solution's correctness.
