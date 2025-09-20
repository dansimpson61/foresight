# Foresight Testing Strategy

## Guiding Philosophy: "Joyful Confidence"

Our testing strategy aligns with our "Ode to Joy" development philosophy. A well-tested system is not a burden; it is a source of confidence and a joy to evolve. Tests are not an afterthought; they are a fundamental part of the design process, ensuring that every component behaves exactly as intended.

Our strategy is built on the principle of the "Testing Pyramid," which gives us fast, precise feedback where we need it most and ensures the overall system is reliable.

## The Testing Pyramid

We employ a multi-layered approach to testing:

### 1. Unit Tests (The Foundation)

This is the most critical layer of our suite.

-   **Purpose**: To verify that each individual class (a "unit") performs its specific business logic correctly and in complete isolation.
-   **What to Test**: We test the public methods of our model classes. For example:
    -   `Person`: Does it calculate age and RMD eligibility correctly according to SECURE 2.0 rules?
    -   `Account` subclasses: Does a `TraditionalIRA` withdrawal correctly generate taxable income? Does a `TaxableBrokerage` withdrawal correctly calculate capital gains?
    -   `IncomeSource` subclasses: Does `SocialSecurityBenefit` correctly apply reductions or credits based on claiming age?
    -   `TaxYear`: Does it calculate taxes correctly for a given income, including the nuances of capital gains and IRMAA?
-   **Characteristics**:
    -   **Fast**: They run in milliseconds.
    -   **Isolated**: They use `instance_double` to mock dependencies, so a failure in one unit's test points directly to a bug in that unit.
    -   **Numerous**: This layer has the largest number of tests.

### 2. Integration Tests (The Middle Layer)

-   **Purpose**: To verify that a small group of collaborating classes work together as intended.
-   **What to Test**: We test the interaction points between key components. For example:
    -   `AnnualPlanner` + `TaxYear` + `ConversionStrategies`: Does the planner correctly sequence events, pass the right income figures to the `TaxYear`, and use the `Strategy`'s output to generate a `RothConversion` event? We verify the data flow and orchestration.
-   **Characteristics**:
    -   **Slower than Unit Tests**: They involve multiple real objects.
    -   **Focused**: A failure here points to a bug in the *interaction* between specific components.

### 3. Feature/Acceptance Tests (The Peak)

This is the final verification that the system delivers on its user-facing promises.

-   **Purpose**: To test a complete feature from the user's perspective, from the web request to the final result.
-   **What to Test**:
    -   **API Contract (`request` specs)**: Does the `POST /plan` endpoint correctly receive a valid JSON payload, pass it to the `PlanService`, and return a well-formed JSON response? This is a critical test of our data contracts.
    -   **UI Behavior (`feature` specs)**: Does the user interface correctly render the data returned from the API? Does a slider update the chart?
-   **Characteristics**:
    -   **Slowest**: They involve the entire application stack.
    -   **Few in Number**: We rely on the lower layers to catch most bugs. These tests are for "golden path" scenarios and to ensure all the pieces are wired together correctly.

### Frontend Testing: Isolating the UI

A crucial principle for our UI tests is **isolating the frontend from the backend**.

-   **Isolate with Mocked API Calls**: Our feature specs do not rely on the full backend simulation. Instead, we intercept the `POST /plan` request and return a static JSON fixture file.
-   **Benefits of Mocking**:
    -   **Speed**: The test runs instantly without waiting for the simulation.
    -   **Reliability**: The test will never fail because of a bug in the backend simulation; it only tests the frontend's ability to render a known-good payload.
    -   **Precision**: We can create specific fixture files to test edge cases in the visualization (e.g., a year with zero income, a year with a massive tax bill).
