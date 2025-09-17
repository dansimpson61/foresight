# Foresight Decision-Making Framework

This document begins by defining the core purpose of the Foresight tool: the specific, high-stakes decisions it helps users make and the real-world actions it informs.

---

### A. The Purpose of the Tool: Aiding Strategic Decisions

Foresight is an analytical tool designed to demystify the complex interplay between retirement income, taxes, and strategic financial choices. It provides clear, actionable estimations to help users navigate critical trade-offs, primarily related to tax management and portfolio longevity.

The core user interaction is **scenario comparison**: evaluating a proposed "Strategy" against a "Do Nothing Baseline" to understand its long-term impact.

### B. Key Decisions Aided by Foresight

The analysis and visualizations presented by the tool are intended to help users confidently answer the following questions:

1.  **The Core Roth Conversion Question: Should I do Roth conversions at all?**
    *   By comparing a conversion strategy to the baseline, the user can determine if the long-term tax savings and increased tax-free assets justify the upfront tax cost.

2.  **The Timing Question: *When* is the optimal time for me to do conversions?**
    *   The tool helps identify the "sweet spot" years for conversions, typically the low-income window between retirement and the start of RMDs and Social Security, where they can convert at the lowest possible marginal tax rate.

3.  **The Sizing Question: *How much* should I convert each year?**
    *   Users can test different strategies (e.g., converting a fixed amount vs. converting just enough to fill a specific tax bracket) to see how each impacts their lifetime tax bill and end-of-plan assets.

4.  **The Medicare Question: How will my strategy affect my future Medicare premiums?**
    *   The IRMAA timeline provides direct, visual feedback on whether a given year's income (including a conversion) will trigger a significant premium surcharge two years later, allowing the user to smooth out conversions to avoid these costly thresholds.

5.  **The Sustainability Question: Will my money last through my retirement?**
    *   The "Portfolio Exhaustion Year" metric provides a clear, immediate answer on the sustainability of the user's spending plan when combined with their chosen financial strategy. It highlights potential trade-offs between tax efficiency and longevity.

6.  **The Withdrawal Question: What is the most effective order to withdraw from my accounts in retirement?**
    *   The tool allows the user to model and compare different withdrawal hierarchies (e.g., Taxable-first vs. Traditional-first) to see the impact on taxes paid and portfolio longevity.

### C. Actions Informed by the Analysis

The insights gained from answering the questions above empower the user to take concrete, real-world actions:

*   **Execute a Roth Conversion:** Confidently instruct a financial institution to perform a Roth conversion of a specific, analytically-backed amount.
*   **Forgo a Roth Conversion:** Decide *not* to perform a conversion in a given year because the analysis shows a net negative impact (e.g., triggering an unacceptable IRMAA surcharge).
*   **Optimize Social Security Timing:** Adjust their planned Social Security claiming age to better create a low-income window for more efficient conversions.
*   **Implement a Withdrawal Plan:** Systematically draw down funds in retirement according to the most tax-efficient order discovered during the analysis.
*   **Adjust Retirement Spending:** Modify their planned annual expenses after seeing the impact on their portfolio's long-term sustainability.
*   **Inform Tax Planning:** Use the year-by-year tax projections to work with a tax professional on withholding or quarterly estimated tax payments.

---
---

# Foresight Data Strategy: Inputs and Outputs

### A. Modeling the Withdrawal Strategy

A withdrawal strategy is the logic used to cover annual spending shortfalls when expenses exceed available income. This model is executed each year of the simulation after income and taxes are calculated.

**1. Trigger Condition:**
A withdrawal is triggered if `Annual Expenses` are greater than `Net Annual Income`.
*   `Net Annual Income` is defined as all income streams (salary, Social Security, pensions) and Required Minimum Distributions (RMDs), minus all calculated taxes for the year (Federal, State, Capital Gains).

**2. The Shortfall Calculation:**
*   `Shortfall = Annual Expenses - Net Annual Income`
*   If this value is positive, the withdrawal strategy is executed.

**3. The Withdrawal Hierarchy:**
The core of the strategy is a user-defined, ordered list of accounts from which to draw funds to cover the shortfall. The simulation will pull from the accounts in sequence until the shortfall is zero.
*   **Example of a common tax-optimized hierarchy:**
    1.  `Cash / Savings` (No tax impact, drawn down only to the specified `Emergency Fund` floor)
    2.  `Taxable Brokerage` (Potential for capital gains tax)
    3.  `Traditional IRA/410k` (Taxed as ordinary income)
    4.  `Roth IRA/401k` (No tax impact, but last resort to preserve tax-free growth)

**4. Interaction with RMDs:**
*   RMDs are **forced withdrawals** from Traditional accounts that occur regardless of spending needs.
*   Therefore, in the simulation's order of operations, RMDs are calculated and their resulting cash is added to the year's income *before* the shortfall is calculated. This correctly models that RMDs can help cover expenses.

---

### B. Essential Parameters (The Inputs)

These are the data points the tool *must* collect to run a credible simulation, grouped by purpose.

*   **1. Household & Demographics:**
    *   `Person 1 Age`, `Person 2 Age` (if applicable)
    *   `Filing Status`, `State of Residence`
    *   `Analysis Horizon` (Number of years to simulate)

*   **2. Financial State (Assets & Liabilities):**
    *   `Cash / Savings Balance`
    *   `Emergency Fund` (The floor below which the `Cash / Savings Balance` should not be drawn for spending shortfalls)
    *   `Traditional IRA/401k Balance`
    *   `Roth IRA/401k Balance`
    *   `Taxable Brokerage Balance` & `Cost Basis`
    *   `Other Assets` (for net worth calculation)
    *   `Liabilities` (for net worth calculation)

*   **3. Income Streams (Annual):**
    *   `Base Income / Salary`
    *   `Pension Benefit`
    *   `Social Security Benefit at Full Retirement Age (FRA)` and `Planned Claiming Age`. The tool will then calculate the actual benefit received based on standard SSA rules for early or delayed claiming.
    *   *Note: This section includes user-defined, recurring income sources. Calculated, non-discretionary cash flows like Required Minimum Distributions (RMDs) are handled by the simulation logic each year and are not listed here as an input.*

*   **4. Spending Plan:**
    *   `Annual Expenses` (to be adjusted for inflation annually)

*   **5. Strategic Scenarios (Variables for Comparison):**
    *   `Roth Conversion Strategy` ("Do Nothing", "Fixed Amount", etc.) with its parameters.
    *   `Withdrawal Hierarchy` (The ordered list of accounts as defined in the model above).

*   **6. Economic Assumptions:**
    *   `General Inflation Rate`, `Investment Growth Rates`, `Income Growth Rate`

---

### C. Critical Information for Decision-Making (The Outputs)

These are the results the tool *must* present to the user.

*   **1. High-Level Aggregate Metrics (The "Scorecard"):**
    *   `Lifetime Total Taxes Paid`, `Total Amount Converted to Roth`
    *   `Ending Net Worth`, `Ending Balances` for each account type
    *   `Tax-Free Percentage of Final Net Worth`
    *   `Portfolio Exhaustion Year` (if applicable)

*   **2. Year-by-Year Data (The "Details Table"):**
    *   `Year` & `Ages`, `Annual Expenses`
    *   `Sources of Income`, `Required Minimum Distribution (RMD)` Amount
    *   `Net Cash Flow` (Income - Expenses - Taxes, before strategic withdrawals)
    *   `Withdrawal from Cash`, `from Taxable`, `from Traditional`, `from Roth` (to cover shortfall)
    *   `Roth Conversion Amount`
    *   `Total Taxable Income`, `Marginal & Effective Tax Rates`
    *   `All Tax Types` (Federal, State, etc.), `MAGI`, `IRMAA Tier & Surcharge Cost`
    *   `Ending Balance` for each account type

*   **3. Key Insight Visualizations (The "Story"):**

    *   **1. Net Worth Over Time (Stacked Area Chart):** This chart tells the story of wealth accumulation.
        *   **Layers:** Stacked areas for `Cash`, `Taxable`, `Traditional`, and `Roth` balances. `Other Assets` can be included to give a full Net Worth picture.
        *   **Purpose:** Shows the overall growth and composition of the user's portfolio, clearly illustrating the shift from tax-deferred to tax-free assets as a result of the chosen strategy.

    *   **2. Annual Income & Tax Details (Stacked Area Chart with Overlays):** This chart tells the story of the user's annual tax situation, visualizing how different income sources build up and interact with the tax system.
        *   **Y-Axis:** The vertical axis represents total annual income, corresponding to the tax bracket thresholds.
        *   **Layers (Bottom to Top):** The stacked areas represent the components of the year's taxable income in a logical order:
            1.  `Taxable Social Security`
            2.  `Pensions & Other Income`
            3.  `Salary / Pre-retirement Income`
            4.  `Capital Gains Realized` (from taxable withdrawals)
            5.  `Forced Withdrawals` (RMDs and necessary Traditional IRA withdrawals for spending)
            6.  `Roth Conversion` (The discretionary, a strategic component)
        *   **Overlays (as subtle horizontal lines or shaded regions):**
            *   Federal Tax Bracket thresholds for ordinary income.
            *   Key IRMAA MAGI thresholds.
        *   **Overlay (as a line chart):** Total Annual Tax Liability.
        *   **Purpose:** To make the relationship between income and taxes visually explicit. A user can see exactly how a discretionary Roth Conversion "fills up" the space within a chosen tax bracket, providing immediate feedback on the core "Sizing Question" ("How much should I convert?"). It also shows how close their total income is to triggering higher taxes or IRMAA surcharges.

    *   **3. Future Medicare Surcharge Risk (IRMAA Timeline):** A simplified, color-coded bar showing the projected IRMAA tier for each year of the plan.

    *   **4. End-State Comparison (Tax-Efficiency Gauge):** A simple bar chart comparing the final portfolio composition (Roth vs. Traditional) of the user's strategy against the "Do Nothing" baseline.
