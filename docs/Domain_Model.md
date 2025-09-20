The purpose of this document is to produce a comprehensive catalog of every module, class, and method, detailing its purpose, data flow, and operational logic.

The development philosophy and guiding principles of the Forsight project are contained in the "Ode to Joy" document. It emphasizes:

- **Elegance and Perfection:** Writing code that is not only functional but also a pleasure to read, write, and maintain.
- **Excellent Code:** Prioritizing readability, maintainability, testability, and robustness.
- **Excellent OOP:** Clear abstractions, well-defined responsibilities, and effective use of Ruby's features.
- **Sinatra Best Practices:** Simplicity, convention over configuration, and modularity.
- **Minimalism in JavaScript:** Using StimulusJS to avoid "intentional ugliness."

Now, I will examine your design documents to understand the intended architecture and data flow of the application.

.

I have now reviewed all of the high-level documentation.

- **Ode to Joy:** Emphasizes elegant, maintainable, and well-tested code.
- **DATA_STRATEGY.md:** Defines the core purpose of the application—to help users make strategic financial decisions, particularly around Roth conversions, by comparing a "Strategy" scenario to a "Do Nothing Baseline." It details the necessary inputs (household info, assets, income, etc.) and the critical outputs (aggregate metrics, year-by-year data, and key visualizations).
- **FRONTEND_PLAN.md:** Outlines a minimalist front-end architecture using Sinatra, Slim, and StimulusJS. It defines the API endpoints, data contracts, and a phased approach to building the UI, starting with a simple data table and progressively adding visualizations.
- **UX-UI Design Spec.md:** Provides a detailed vision for a clean, data-focused interface. It specifies the user flow, wireframes for the control and analysis dashboards, and a design system (colors, typography, etc.). The emphasis is on clarity, immediate feedback, and "joyful minimalism."

My next step is to dive into the code itself, starting with the main application entry point, `app.rb`, to understand how the server is structured and how it handles requests. Then I will proceed to catalog all the modules.

.

Okay, `app.rb` is the main entry point. It's a simple Sinatra application that mounts two other applications: `Foresight::API` and `Foresight::UI`. This is a good separation of concerns.

I will now examine `app/api.rb` and `app/ui.rb` to understand the routing and application logic. Starting with `app/api.rb`.

.

This file defines the `Foresight::API` Sinatra application, which handles the JSON API for the Foresight tool.

**Module: Foresight Class: API** (inherits from `Sinatra::Base`)

**Purpose:** To provide a structured JSON API for running financial simulations. It handles incoming requests, validates them, passes them to the core PlanService, validates the results, and returns a JSON response.

**Routes:**

- **GET /**
    **Purpose:** A simple health check endpoint.
    **Data In:** None.
    **Logic:** Returns a JSON object with the service status, name, and the schema version from `Foresight::PlanService`.
    **Data Out:** JSON containing status, service, and version.
- **GET /strategies**
    **Purpose:** To list the available financial strategies that the simulation engine can run.
    **Data In:** None.
    **Logic:** Instantiates a `Foresight::PlanService` and calls the `list_strategies` method.
    **Data Out:** JSON containing a list of available strategies.
- **POST /plan**
    **Purpose:** The main endpoint for running a financial simulation.
    **Data In:** A JSON payload containing the user's financial data and desired strategies.
    **Logic:**
    - Parses the incoming JSON.
    - Validates the request payload against a contract using `Foresight::ContractValidator`. Halts with a 400 error if invalid.
    - Calls `Foresight::PlanService.run` with the validated parameters.
    - Validates the response from the `PlanService` against a contract. This is a crucial step to ensure the backend doesn't send malformed data to the frontend. Halts with a 500 error if the service produces invalid data.
    - Wraps the result in a standard response format.
    - Includes robust error handling for JSON parsing, contract validation, and simulation engine exceptions.
    **Data Out:** A JSON object containing the detailed results of the simulation.
- **GET /plan/example**
    **Purpose:** Provides a sample JSON payload to demonstrate the required input structure for the `/plan` endpoint.
    **Data In:** None.
    **Logic:** Returns a hardcoded hash representing a typical user scenario.
    **Data Out:** A JSON object representing an example input payload.

**Helpers:**

- `json_params`
    **Purpose:** To safely parse the JSON request body.
    **Logic:** Reads and parses the request body. Includes error handling for malformed JSON, returning a 400 error if parsing fails.
    **Returns:** A symbolized hash of the JSON body.
- `wrap_response(payload)`
    **Purpose:** To standardize the JSON response format.
    **Logic:** Takes a payload hash and wraps it within a metadata object containing a timestamp and sender/receiver information.
    **Returns:** A JSON string.

**Key Dependencies:**

- `Sinatra::Base`: The web framework.
- `JSON`: For parsing and generating JSON.
- `Foresight::PlanService`: The core simulation engine.
- `Foresight::ContractValidator`: For validating the data contracts between the API and the PlanService, and between the client and the API.

**Overall Assessment:** This API is well-structured and adheres to the "Ode to Joy" philosophy. It demonstrates excellent separation of concerns, robust error handling, and a commitment to data integrity through the use of contract validation on both requests and responses. The code is clean, readable, and follows best practices for a Sinatra-based API.

Now, I will examine `app/ui.rb`.

.

This file defines the `Foresight::UI` Sinatra application, which serves the front-end of the Foresight tool.

**Module: Foresight Class: UI** (inherits from `Sinatra::Base`)

**Purpose:** To provide the user interface for the application. It serves the main HTML page and a helper page for testing the API.

**Routes:**

- **GET /ui**
    **Purpose:** To render the main user interface of the application.
    **Data In:** None.
    **Logic:**
    - It instantiates a `Foresight::PlanService`.
    - It calls `list_strategies` on the service to get the available financial strategies.
    - It renders the `ui.slim` template, passing the `@strategies` instance variable to it.
    **Data Out:** An HTML page generated from the `ui.slim` template.
- **GET /plan**
    **Purpose:** This route provides a simple, developer-focused HTML page to manually test the `POST /plan` API endpoint. It's a debugging and development tool, not part of the main user flow.
    **Data In:** None.
    **Logic:**
    - Returns a static HTML page with a textarea for JSON input and a "Run" button.
    - Includes embedded JavaScript to:
        - Fetch the example payload from `/plan/example` and populate the textarea.
        - Take the content of the textarea, send it as a `POST` request to `/plan`, and display the raw JSON response in a `<pre>` tag.
    **Data Out:** A self-contained HTML page for API testing.

**Key Dependencies:**

- `Sinatra::Base`: The web framework.
- `slim`: The templating engine for rendering the UI.
- `Foresight::PlanService`: To get the list of available strategies for the UI.

**Overall Assessment:** The `Foresight::UI` application is simple and focused. It correctly separates the UI from the API. The `/ui` route is the primary entry point for users, rendering the main interface. The `/plan` route is a thoughtful addition for development and testing, embodying the principle of making the development process easier. This aligns with the "Joyful Development" philosophy.

I will now examine the `foresight.rb` file to understand the core `PlanService`.

.

This `foresight.rb` file is the central point for loading all the necessary model components in the correct dependency order. It acts as a manifest for the core domain logic of the application.

Based on the file's `require` statements, I can infer the overall structure of the simulation engine. The analysis will proceed by examining each of these files in the order they are loaded.

**Inferred Structure:**

- **Core Entities:** `person.rb`, `accounts.rb`, `income_sources.rb` likely define the basic building blocks of a financial profile.
- **Aggregation:** `household.rb` probably aggregates `Person`, `Account`, and `IncomeSource` objects into a single unit.
- **Tax Logic:** `tax_year.rb` likely encapsulates the complex logic for calculating annual taxes based on income, deductions, and filing status.
- **Strategic Logic:** `conversion_strategies.rb` probably defines the different Roth conversion strategies the user can choose from.
- **Annual Simulation:** `annual_planner.rb` likely simulates a single year of financial activity, including income, expenses, taxes, and strategic moves.
- **Lifecycle Simulation:** `life_planner.rb` probably orchestrates the `AnnualPlanner` over the entire analysis horizon (e.g., 30 years).
- **Service Layer:** `plan_service.rb` likely acts as the main entry point for the simulation, taking user input, running the `LifePlanner`, and formatting the results.
- **Post-Analysis:** `phase_analyzer.rb` might perform analysis on the completed simulation to identify key financial phases or events.

This is a logical and well-organized structure. I will now proceed to analyze each file in this order to build a comprehensive catalog of the system's components.

Starting with `models/person.rb`.

.

**Module: Foresight Class: Person**

**Purpose:** This class models an individual person within the financial simulation. It encapsulates their basic demographic information and provides methods for calculating age-related financial milestones, specifically related to Required Minimum Distributions (RMDs).

**Attributes:**

- `name` (String): The person's name.
- `date_of_birth` (Date): The person's date of birth.

**Methods:**

- `initialize(name:, date_of_birth:)`
    **Purpose:** The constructor for the `Person` class.
    **Data In:** A `name` (String) and a `date_of_birth` (String or Date).
    **Logic:** Stores the name and parses the `date_of_birth` into a `Date` object.
- `age_in(year)`
    **Purpose:** Calculates the person's age in a given calendar year.
    **Data In:** A `year` (Integer).
    **Logic:** Calculates the age based on the difference in years, adjusting for whether the person's birthday has occurred yet in that year.
    **Data Out:** The person's age (Integer).
- `rmd_start_age`
    **Purpose:** Determines the age at which the person must start taking RMDs, based on the SECURE 2.0 Act rules.
    **Data In:** None.
    **Logic:** Uses a conditional to check the person's birth year. If born in 1960 or later, the RMD age is 75; otherwise, it is 73. It uses memoization (`||=`) to cache the result.
    **Data Out:** The RMD start age (73 or 75).
- `rmd_eligible_in?(year)`
    **Purpose:** Checks if the person is required to take an RMD in a specific year.
    **Data In:** A `year` (Integer).
    **Logic:** Compares the person's age in the given year to their calculated `rmd_start_age`.
    **Data Out:** `true` if the person is of RMD age, `false` otherwise.

**Private Methods:**

- `before_birthday?(year)`
    **Purpose:** A helper method to determine if the person's birthday has already passed in the given year.
    **Logic:** Compares the current date to the person's birthday in the target year.
    **Data Out:** 1 if the birthday has not yet passed, 0 otherwise. This is used as a correction factor in the `age_in` calculation.

**Overall Assessment:** A clean, focused, and well-designed model class. It correctly encapsulates the data and logic related to a person. The implementation of the SECURE 2.0 Act rules for RMDs is a key piece of domain knowledge that is correctly isolated within this class. The code is readable and follows the principle of single responsibility.

Next, I will analyze `models/accounts.rb`.

.

**Module: Foresight**

**Purpose:** This file defines a hierarchy of classes to model various types of financial accounts. It uses inheritance to share common behaviors like holding a balance and growing over time, while specific withdrawal and tax logic is implemented in the subclasses.

**Class: Account** (Base Class)

**Purpose:** The fundamental building block for all other account types.
**Attributes:**
- `balance` (Float): The current balance of the account.
**Methods:**
- `initialize(balance:)`: Sets the initial balance.
- `grow(rate)`: Increases the balance by a given growth rate.

**Class: OwnedAccount** (Inherits from `Account`)

**Purpose:** An abstract subclass for accounts that have a single owner.
**Attributes:**
- `owner` (Person): The person who owns the account.
**Methods:**
- `initialize(owner:, balance:)`: Sets the owner and initial balance.

**Class: Cash** (Inherits from `Account`)

**Purpose:** Models a simple cash account.
**Methods:**
- `withdraw(amount)`:
    **Logic:** Decreases the balance by the requested amount (but not below zero).
    **Data Out:** A hash detailing the transaction: `{ cash: amount_withdrawn, taxable_ordinary: 0.0, taxable_capital_gains: 0.0 }`. This establishes a clear data contract for withdrawal operations.

**Class: TraditionalIRA** (Inherits from `OwnedAccount`)

**Purpose:** Models a tax-deferred retirement account.
**Methods:**
- `withdraw(amount)`:
    **Logic:** Decreases the balance. The entire withdrawal amount is considered ordinary income for tax purposes.
    **Data Out:** `{ cash: amount_withdrawn, taxable_ordinary: amount_withdrawn, taxable_capital_gains: 0.0 }`.
- `convert_to_roth(amount)`:
    **Logic:** Simulates a Roth conversion. Decreases the balance, and the entire amount is taxable.
    **Data Out:** `{ converted: amount_converted, taxable_ordinary: amount_converted }`.
- `calculate_rmd(age)`:
    **Logic:** Calculates the Required Minimum Distribution for a given year. It checks if the owner's age meets the RMD threshold and then uses a static `RMD_TABLE` (based on IRS Uniform Lifetime Table) to find the appropriate divisor.
    **Data In:** The owner's age (Integer).
    **Data Out:** The RMD amount (Float), or 0.0 if not applicable.

**Class: RothIRA** (Inherits from `OwnedAccount`)

**Purpose:** Models a tax-free retirement account.
**Methods:**
- `withdraw(amount)`:
    **Logic:** Decreases the balance. Withdrawals are not taxed.
    **Data Out:** `{ cash: amount_withdrawn, taxable_ordinary: 0.0, taxable_capital_gains: 0.0 }`.
- `deposit(amount)`:
    **Logic:** Increases the balance, used to receive funds from a Roth conversion.

**Class: TaxableBrokerage** (Inherits from `Account`)

**Purpose:** Models a standard brokerage account where gains are taxed.
**Attributes:**
- `owners` (Array of Person): The owners of the account.
- `cost_basis_fraction` (Float): The proportion of the balance that is the original investment (cost basis).
**Methods:**
- `initialize(...)`: Sets owners, balance, and a sanitized `cost_basis_fraction`.
- `withdraw(amount)`:
    **Logic:** Decreases the balance. A portion of the withdrawal, calculated as `amount * (1 - cost_basis_fraction)`, is considered a capital gain for tax purposes.
    **Data Out:** `{ cash: amount_withdrawn, taxable_ordinary: 0.0, taxable_capital_gains: gains_portion }`.

**Overall Assessment:** This file demonstrates excellent object-oriented design.

- **Clear Hierarchy:** The use of inheritance (`Account` -> `OwnedAccount`) effectively reduces code duplication.
- **Polymorphism:** All account types respond to a `withdraw` method, but each provides a different implementation based on its specific tax rules. This is a powerful and clean way to handle the different behaviors.
- **Single Responsibility:** Each class is responsible for its own logic. The `TraditionalIRA` knows about RMDs, the `TaxableBrokerage` knows about capital gains, and so on. This makes the code easy to understand and maintain.
- **Clear Data Contracts:** The `withdraw` methods all return a hash with a consistent structure (`cash`, `taxable_ordinary`, `taxable_capital_gains`). This is a crucial design choice that makes the calling code (likely the `AnnualPlanner`) much simpler, as it can treat all withdrawals uniformly.

This is a solid foundation for the simulation engine. Next, I will analyze `models/income_sources.rb`.

### `models/income_sources.rb` Analysis

**Module: Foresight**

**Purpose:** This file defines classes for various types of income that a household can receive. It uses a base class and inheritance to model shared characteristics, with subclasses implementing specific rules for benefit calculations and taxability.

**Class: IncomeSource** (Base Class)

**Purpose:** The fundamental building block for all income types.
**Attributes:**
- `recipient` (Person): The person receiving the income.
**Methods:**
- `initialize(recipient:)`: Sets the recipient.

**Class: Salary** (Inherits from `IncomeSource`)

**Purpose:** Models a simple annual salary.
**Attributes:**
- `annual_gross` (Float): The gross amount of the salary.
**Methods:**
- `initialize(recipient:, annual_gross:)`: Sets the recipient and gross amount.

**Class: Pension** (Inherits from `IncomeSource`)

**Purpose:** Models an annual pension benefit.
**Attributes:**
- `annual_gross` (Float): The gross amount of the pension.
**Methods:**
- `initialize(recipient:, annual_gross:)`: Sets the recipient and gross amount.
- `taxable_amount(state:, recipient_age:)`:
    **Purpose:** Calculates the taxable portion of the pension.
    **Data In:** The recipient's state and age.
    **Logic:** Contains simplified, state-specific tax logic. For New York (NY), it models a $20,000 exclusion for recipients aged 59.5 or older.
    **Data Out:** The taxable amount of the pension (Float).

**Class: SocialSecurityBenefit** (Inherits from `IncomeSource`)

**Purpose:** Models Social Security benefits, encapsulating the complex rules around claiming age and benefit adjustments.
**Attributes:**
- `pia_annual` (Float): The Primary Insurance Amount—the benefit the recipient would receive at their Full Retirement Age (FRA).
- `claiming_age` (Integer): The age at which the recipient plans to start receiving benefits.
**Methods:**
- `initialize(recipient:, pia_annual:, claiming_age:)`: Sets the recipient, PIA, and claiming age.
- `annual_benefit_for(year)`:
    **Purpose:** Calculates the actual benefit received in a given year.
    **Data In:** The simulation year (Integer).
    **Logic:** Returns 0.0 if the recipient is younger than their `claiming_age`. Otherwise, it calculates the benefit by multiplying the `pia_annual` by an adjustment factor based on the claiming age relative to the recipient's Full Retirement Age.
    **Data Out:** The annual Social Security benefit (Float).

**Private Methods** (`claiming_adjustment_factor`, `early_reduction_factor`, `delayed_credit_factor`, `full_retirement_age_years`):
**Purpose:** These methods contain the detailed, isolated business logic for Social Security calculations, based on official Social Security Administration rules. They handle reductions for claiming early, credits for claiming late, and determining the recipient's specific Full Retirement Age based on their birth year.

**Overall Assessment:**

- **Excellent Encapsulation:** This is a prime example of good object-oriented design. The incredibly complex logic of Social Security benefit calculation is completely hidden away within the `SocialSecurityBenefit` class. The rest of the application doesn't need to know how the benefit is calculated, only that it can ask the object for the correct amount for a given year.
- **Domain Modeling:** The classes accurately model the real-world concepts of different income streams.
- **Clarity and Readability:** The methods, especially the private helper methods in `SocialSecurityBenefit`, have clear names that describe their purpose, making the complex logic easier to follow.
- **Extensibility:** The inheritance structure makes it easy to add new types of income in the future (e.g., `RentalIncome`, `Royalties`) with their own unique rules.

This file effectively isolates complex, rule-based calculations into clean, maintainable, and testable components. I'll now proceed to `models/household.rb`.

.

I see that `household.rb` depends on `rmd_calculator.rb`, which I haven't analyzed yet. I will analyze `rmd_calculator.rb` first to maintain the correct dependency order.

.
### `models/rmd_calculator.rb` Analysis

**Module: Foresight Class: RmdCalculator**

**Purpose:** This class is a dedicated service object responsible for a single task: calculating the Required Minimum Distribution (RMD) for a given age and account balance.

**Class Methods:**

- `self.calculate(age:, balance:)`
    **Purpose:** To compute the RMD amount.
    **Data In:**
    - `age` (Integer): The age of the account owner.
    - `balance` (Float): The year-end balance of the retirement account from the previous year.
    **Logic:**
    - It performs an age check. Although the `Person` class correctly identifies the nuanced RMD start age (73 or 75), this calculator uses a more conservative check (age < 72) as a fallback. This suggests a potential area for future refactoring to ensure consistency.
    - It looks up the appropriate "distribution period" (divisor) from the `UNIFORM_LIFETIME_TABLE` constant using the person's age.
    - It divides the balance by the divisor to determine the RMD amount.
    - It rounds the result to two decimal places.
    **Data Out:** The calculated RMD amount (Float), or 0.0 if the person is not of RMD age or the age is outside the table's range.

**Constants:**

- `UNIFORM_LIFETIME_TABLE`
    **Purpose:** A frozen hash that stores the official IRS Uniform Lifetime Table, which is used to determine the RMD divisor for most IRA owners. This is a classic example of embedding critical, static domain data directly into the code.

**Overall Assessment:**

- **Single Responsibility Principle:** This class is an excellent example of the Single Responsibility Principle. It does one thing and does it well. It isolates the RMD calculation logic and the IRS data table from the `Account` or `Person` models.
- **Separation of Concerns:** By moving the `RMD_TABLE` from the `TraditionalIRA` class (where a version of it was) into this dedicated calculator, the design is improved. The `TraditionalIRA` is responsible for its own state, while the `RmdCalculator` is responsible for applying a general rule to that state. This is a subtle but important distinction that enhances maintainability. If the IRS changes the table, only this one file needs to be updated.
- **Clarity:** The code is straightforward and easy to understand.
- **Potential Refinement:** The comment *A more precise implementation would check the birth year* highlights a slight duplication of logic with the `Person` class. The system would be more robust if the RMD `eligible?` check was solely the responsibility of the `Person` object, and this calculator was only responsible for the division. However, as it stands, it is a clear and functional service.

Now I will proceed with `models/household.rb`.

.
I've analyzed `rmd_calculator.rb` and can now proceed with `household.rb`.

**Module: Foresight Class: Household**

**Purpose:** This class acts as an aggregator and a central organizing unit for the entire financial simulation. It brings together all the individual components (`Person`, `Account`, `IncomeSource`) that define a user's financial life into a single, cohesive object.

**Attributes:**

- `members` (Array of Person): The individuals in the household.
- `filing_status` (Symbol): The tax filing status (e.g., `:mfj`, `:single`).
- `state` (String): The state of residence for tax purposes.
- `accounts` (Array of Account subclasses): All financial accounts.
- `income_sources` (Array of IncomeSource subclasses): All sources of income.
- `annual_expenses` (Float): The household's total spending for a year.
- `emergency_fund_floor` (Float): The minimum balance to maintain in cash accounts.
- `withdrawal_hierarchy` (Array of Strings): The user-defined order for withdrawing funds to cover expenses (e.g., `['taxable', 'traditional', 'roth']`).

**Methods:**

- `initialize(...)`
    **Purpose:** The constructor.
    **Data In:** Takes all the core financial data points as keyword arguments.
    **Logic:** Assigns the input data to instance variables, ensuring `annual_expenses` and `emergency_fund_floor` are floats and `filing_status` is a symbol.
- `net_worth`
    **Purpose:** Calculates the total net worth of the household.
    **Logic:** Sums the balances of all accounts.
    **Data Out:** Total net worth (Float).
- `rmd_for(year)`
    **Purpose:** Calculates the total Required Minimum Distribution for all eligible members in a given year.
    **Data In:** The simulation `year` (Integer).
    **Logic:**
    - Iterates through each member of the household.
    - Finds all `TraditionalIRA` accounts belonging to that member.
    - For each IRA, it calls the `RmdCalculator.calculate` service with the member's age and the account balance.
    - Sums the results to get a total RMD for the household.
    **Data Out:** The total RMD amount (Float).
- **Convenience Filter Methods** (`cash_accounts`, `pensions`, `salaries`, etc.)
    **Purpose:** These methods provide a clean, readable way to access filtered lists of specific account or income source types. For example, `traditional_iras` returns only the `TraditionalIRA` objects from the `@accounts` array.
    **Logic:** They use `select` with `is_a?` to filter the arrays.
    **Data Out:** An array of objects of the specified type.
- `grow_assets(growth_assumptions:, inflation_rate:)`
    **Purpose:** To advance the financial state of the household by one year, applying investment growth and inflation.
    **Data In:**
    - `growth_assumptions` (Hash): A hash mapping account types (e.g., `:traditional_ira`) to annual growth rates.
    - `inflation_rate` (Float): The annual inflation rate.
    **Logic:**
    - Merges the provided `growth_assumptions` with a default hash to ensure all keys are present.
    - Iterates through each account type and calls the `grow` method on