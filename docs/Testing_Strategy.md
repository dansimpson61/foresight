# A Multi-Layered Testing Strategy for Joyful Confidence

> Given our project's philosophy, "Thorough Testing" is not just about preventing bugs, but about ensuring the joy and confidence of the end-user who relies on these numbers. A comprehensive testing strategy for a system like this should be multi-layered, moving from the smallest computational units to the final visual presentation. This approach ensures that not only is the math correct in isolation, but that the data flows correctly through the entire system and is presented accurately to the user, fulfilling the promise of the "Tufte Display."

---

### LAYER 1: Foundational Unit Tests (Verifying the Atoms)

This layer focuses on the "small, focused methods" within your models. The goal here is to prove, with mathematical certainty, that the core calculations are correct in isolation.

#### What to Test:

-   **`TaxYear`**: This is the most critical model to test. Create specs with known, verifiable inputs. For example, for a given filing status and income, the federal tax should be exactly a certain amount. Use real-world examples from past tax years to validate this. Test the boundary conditions: what happens if income is exactly on the edge of a tax bracket or an IRMAA tier?
-   **`SocialSecurityBenefit`**: Test the `annual_benefit_for` method. Create specs for a person born in 1959 vs. 1960. Validate the calculated benefit for claiming early (e.g., at 62), at full retirement age, and late (at 70).
-   **Account Models**: Test the `withdraw` and `convert_to_roth` methods. Ensure that a withdrawal from a `TraditionalIRA` correctly generates taxable income, while one from a `RothIRA` does not. Verify that RMD calculations use the correct divisor for a given age.
-   **`Person` Model**: Test the `age_in` and `rmd_eligible_in?` methods, especially around birthday edge cases.

#### How to Test:

-   Use RSpec for focused unit tests (`spec/models/`).
-   Each test should be small, fast, and test one specific behavior.

**Example Spec:**
```ruby
# spec/models/tax_year_spec.rb
it 'correctly calculates taxes for an income within the 22% bracket' do
  tax_year = Foresight::TaxYear.new(year: 2023)
  result = tax_year.calculate(filing_status: :mfj, taxable_income: 100_000)
  # Use a known, pre-calculated value for the assertion
  expect(result[:federal_tax]).to be_within(0.01).of(12579.50)
end
```

---

### LAYER 2: Service-Level Scenario Tests (Verifying the Narrative)

This layer tests the integration of your models by running the `PlanService` with specific, meaningful scenarios. The goal is to verify that the simulation tells a correct and believable financial story over time.

#### What to Test:

Create a few "golden" scenarios that represent key user stories.

-   **The "Sweet Spot" Roth Conversion**: A scenario where a person has a few years of low income between retirement and taking Social Security/RMDs. The test should assert that the `fill_to_top_of_bracket` strategy correctly identifies these years and that the `cumulative_roth_conversions` in the aggregate results match expectations.
-   **The IRMAA Trigger**: A scenario with high income (or a large conversion) that is known to trigger a specific IRMAA tier. The test should run the simulation and assert that for the year the surcharge applies (two years after the high income), the `irmaa_part_b` value in the yearly results is the correct, non-zero amount.
-   **The Withdrawal Hierarchy**: A scenario where expenses force withdrawals. The test should assert that the account balances decrease in the correct order as defined by the `withdrawal_hierarchy` and that the taxable events correspond to the account type being drawn from.

#### How to Test:

-   Use RSpec to test the `PlanService` directly (`spec/models/plan_service_spec.rb`).
-   Construct a complete `params` hash for each scenario and call `PlanService.run`.
-   Parse the resulting JSON and assert against key outcomes in the aggregate or specific yearly results. You don't need to check every single number, just the ones that prove the scenario behaved as expected.

---

### LAYER 3: End-to-End Visual Validation (Verifying the Tufte Display)

This is the final layer, ensuring that the validated, correct data from the backend is rendered perfectly by the frontend, fulfilling the UX/UI vision.

#### What to Test:

-   **Data-to-DOM Binding**: Does the `ending_net_worth` from the last year of the JSON payload correctly render inside the "Net Worth" summary card?
-   **Chart Accuracy**: When the API returns a known, static data set, does the stacked area chart render with the correct proportions? Does the IRMAA timeline show the right colors for the right years?
-   **Interactive State**: When you hover over the chart for year "2030", does the tooltip display the exact numbers from the "2030" entry in the JSON data?

#### How to Test:

-   **Isolate the Frontend with Mocked API Calls**: This is a crucial improvement. Your feature specs should not rely on the full backend simulation. Instead, configure your test environment (e.g., using Capybara and Sinatra's testing helpers) to intercept the `POST /plan` request. When the test sees this request, it should prevent it from hitting the real API and instead return a static JSON fixture file containing a known, golden scenario result.
-   **Benefits of Mocking**:
    -   **Speed**: The test runs instantly without waiting for the simulation.
    -   **Reliability**: The test will never fail because of a bug in the backend simulation; it only tests the frontend's ability to render a known-good payload.
    -   **Precision**: You can create specific fixture files to test edge cases in the visualization (e.g., a year with zero income, a year with a massive tax bill).
-   **Visual Regression Testing (The Ultimate Step)**: For a project that values data visualization this highly, consider a visual regression testing tool (like Percy). After your Capybara test navigates and renders the page with the mocked data, the tool takes a screenshot. This screenshot is compared to a previously approved "baseline" image. If a single pixel differs—a color changes, a line shifts, a label is misaligned—the test fails. This is the most thorough way to guarantee the integrity of your "Tufte Display."
