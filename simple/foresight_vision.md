# Simple Foresight: Living Vision & Planning

*A living document in the spirit of joyful development*

## 🚨 Critical Issues (Fix Immediately)

### Issue #1: Results Zero Out on Edit
**Problem**: When simulation reruns after profile/simulation edit, the results display shows zeros briefly or permanently.

**Root Cause**: JavaScript updates aren't properly updating the DOM with new results.

**Fix Priority**: HIGH - breaks core UX

**Solution Path**:
- Event listeners not properly updating result cards
- Need to update both chart AND result metrics on `profile:updated` and `simulation:updated` events
- Add loading states during re-simulation
- Show spinner or "Calculating..." during POST request

---

### Issue #2: No Persistence (User Frustration)
**Problem**: "Don't make the user have to compensate for our delicate sensibilities" - losing work on refresh is unacceptable.

**The Tension**: We removed localStorage for ideological purity, but this creates real user pain.

**Resolution**: We were wrong about ephemerality. **Users need persistence.**

**Implementation Options**:

#### Option A: Browser Storage (Pragmatic)
```javascript
// Store on every successful simulation
localStorage.setItem('foresight_profile', JSON.stringify(profile));
localStorage.setItem('foresight_last_results', JSON.stringify(results));

// Load on page init
const savedProfile = localStorage.getItem('foresight_profile');
if (savedProfile) {
  // Offer to restore: "Continue from your last session?"
}
```

**Pros**: Zero backend changes, works immediately, respects privacy
**Cons**: Lost if user clears browser data, not sharable

#### Option B: URL-Based State (Elegant)
```javascript
// Encode profile in URL hash
window.location.hash = btoa(JSON.stringify(profile));

// Load from URL on init
const hashProfile = atob(window.location.hash.slice(1));
```

**Pros**: Sharable links, bookmark-able, no storage needed
**Cons**: URL length limits, exposes data in URL

#### Option C: Server-Side Sessions (Robust)
```ruby
# Simple session storage
enable :sessions
set :session_secret, ENV['SESSION_SECRET']

post '/save' do
  session[:profile] = params[:profile]
  session[:results] = params[:results]
end

get '/' do
  @profile = session[:profile] || DEFAULT_PROFILE
  @results = session[:results] || run_initial_simulations
end
```

**Pros**: Reliable, secure, no client limits
**Cons**: Requires session management, not sharable

#### Option D: Named Scenarios (Ultimate)
```ruby
# User-created scenarios with names
post '/scenarios' do
  scenario = {
    name: params[:name],
    profile: params[:profile],
    created_at: Time.now
  }
  # Store in DB or JSON file
end

get '/scenarios' do
  # List all user scenarios
end
```

**Pros**: Multiple scenarios, comparisons, professional feel
**Cons**: Most complex, needs storage backend

**Recommended**: Start with **Option A (localStorage) + Option B (URL hash)** combo:
- Auto-save to localStorage for recovery
- Generate shareable link with URL hash
- Build Option D (Named Scenarios) in Phase 2

**Priority**: HIGH - Implement this week

---

### Issue #3: Multi-Person Households
**Problem**: Real households have 2+ people with different ages, accounts, and income sources.

**Current Limitation**: Single person hardcoded everywhere

**What We Need**:
```yaml
members:
  - name: 'Pat'
    date_of_birth: '1964-05-01'
    role: 'primary'
  - name: 'Sam'  
    date_of_birth: '1966-03-15'
    role: 'spouse'

accounts:
  - type: :traditional
    owner: 'Pat'          # Individual account
    balance: 500000
  - type: :traditional
    owner: 'Sam'          # Spouse's account
    balance: 300000
  - type: :taxable
    owner: 'joint'        # Joint account
    balance: 200000
```

**Complexity Added**:
- RMDs calculated per person's age
- Social Security per person
- Survivor scenarios (one person dies)
- Tax filing status changes (MFJ → Single)

**Implementation Path**:
1. Phase 1: Two-person support (most common)
2. Phase 2: Flexible N-person (rare, but clean architecture)
3. Phase 3: Survivor scenarios and transitions

**Priority**: MEDIUM - Important but complex

---

### Issue #4: Domain Model Refactor
**Problem**: Current code is procedural. Need clean object model.

**Request**: "Think long and hard... sketch out our domain objects"

**Analysis Below** ↓

---

## 🏗️ Domain Model: Assets and Flows

*After thinking long and hard...*

### Core Insight: Two Fundamental Concepts

Everything in retirement planning is either:
1. **Assets** - What you have (stocks, accounts, property)
2. **Flows** - What moves (income, expenses, transfers)

### The Domain Model

```ruby
# ============================================================================
# ASSETS - Things you own that have value
# ============================================================================

class Asset
  attr_reader :balance, :owner, :taxability
  
  def initialize(balance:, owner:, taxability:)
    @balance = balance
    @owner = owner
    @taxability = taxability
  end
  
  # Every asset can grow
  def grow(rate)
    @balance *= (1 + rate)
  end
  
  # Every asset can be withdrawn from
  def withdraw(amount)
    actual = [amount, @balance].min
    @balance -= actual
    actual
  end
  
  # Tax treatment varies by asset type
  def tax_on_withdrawal(amount)
    raise NotImplementedError
  end
end

class TraditionalIRA < Asset
  def initialize(balance:, owner:)
    super(balance: balance, owner: owner, taxability: :tax_deferred)
  end
  
  def tax_on_withdrawal(amount)
    { ordinary_income: amount, capital_gains: 0 }
  end
  
  def rmd_required?(age)
    age >= 73
  end
  
  def calculate_rmd(age)
    return 0 unless rmd_required?(age)
    divisor = RMD_TABLE[age] || 7.1
    @balance / divisor
  end
end

class RothIRA < Asset
  def initialize(balance:, owner:)
    super(balance: balance, owner: owner, taxability: :tax_free)
  end
  
  def tax_on_withdrawal(amount)
    { ordinary_income: 0, capital_gains: 0 }
  end
  
  def rmd_required?(age)
    false  # No RMDs on Roth!
  end
end

class TaxableAccount < Asset
  attr_reader :cost_basis_fraction
  
  def initialize(balance:, owner:, cost_basis_fraction: 0.7)
    super(balance: balance, owner: owner, taxability: :taxable)
    @cost_basis_fraction = cost_basis_fraction
  end
  
  def tax_on_withdrawal(amount)
    gains = amount * (1 - @cost_basis_fraction)
    { ordinary_income: 0, capital_gains: gains }
  end
  
  def generate_dividends(yield_rate)
    @balance * yield_rate
  end
end

class CashAccount < Asset
  def initialize(balance:, owner:)
    super(balance: balance, owner: owner, taxability: :taxable)
  end
  
  def tax_on_withdrawal(amount)
    { ordinary_income: 0, capital_gains: 0 }  # Already taxed
  end
end

# ============================================================================
# FLOWS - Money moving in or out
# ============================================================================

class Flow
  attr_reader :amount, :frequency
  
  def initialize(amount:, frequency: :annual)
    @amount = amount
    @frequency = frequency
  end
  
  # Every flow has tax implications
  def tax_character
    raise NotImplementedError
  end
  
  # Every flow knows when it's active
  def active?(context)
    raise NotImplementedError
  end
  
  # Get the amount for a specific period
  def amount_for_period(context)
    active?(context) ? @amount : 0
  end
end

class IncomeFlow < Flow
  # Income flows IN to the household
end

class ExpenseFlow < Flow
  # Expense flows OUT of the household
  def tax_character
    { deductible: false }  # Most expenses aren't deductible
  end
end

class SocialSecurityIncome < IncomeFlow
  attr_reader :recipient, :pia, :claiming_age
  
  def initialize(recipient:, pia:, claiming_age:)
    @recipient = recipient
    @pia = pia
    @claiming_age = claiming_age
    super(amount: pia)
  end
  
  def active?(context)
    context.age_of(@recipient) >= @claiming_age
  end
  
  def tax_character
    { 
      type: :social_security,
      requires_provisional_income_calc: true,
      max_taxable_portion: 0.85
    }
  end
end

class PensionIncome < IncomeFlow
  attr_reader :recipient, :start_age, :cola_rate
  
  def initialize(recipient:, base_amount:, start_age:, cola_rate: 0)
    @recipient = recipient
    @base_amount = base_amount
    @start_age = start_age
    @cola_rate = cola_rate
    super(amount: base_amount)
  end
  
  def active?(context)
    context.age_of(@recipient) >= @start_age
  end
  
  def amount_for_period(context)
    return 0 unless active?(context)
    years_elapsed = context.years_since_start
    @base_amount * ((1 + @cola_rate) ** years_elapsed)
  end
  
  def tax_character
    { type: :fully_taxable_ordinary }
  end
end

class EmploymentIncome < IncomeFlow
  attr_reader :recipient, :end_year
  
  def initialize(recipient:, salary:, end_year:, contribution_rate: 0)
    @recipient = recipient
    @end_year = end_year
    @contribution_rate = contribution_rate
    super(amount: salary)
  end
  
  def active?(context)
    context.current_year <= @end_year
  end
  
  def retirement_contribution
    @amount * @contribution_rate
  end
  
  def tax_character
    {
      type: :ordinary_income,
      fica_applicable: true,
      retirement_contribution_deductible: true
    }
  end
end

class RMDIncome < IncomeFlow
  # Special: amount is calculated, not fixed
  attr_reader :source_account
  
  def initialize(source_account:)
    @source_account = source_account
    super(amount: 0)  # Calculated dynamically
  end
  
  def amount_for_period(context)
    age = context.age_of(@source_account.owner)
    @source_account.calculate_rmd(age)
  end
  
  def active?(context)
    age = context.age_of(@source_account.owner)
    @source_account.rmd_required?(age)
  end
  
  def tax_character
    { type: :fully_taxable_ordinary }
  end
end

class LivingExpenses < ExpenseFlow
  attr_reader :inflation_rate
  
  def initialize(base_amount:, inflation_rate: 0.03)
    @base_amount = base_amount
    @inflation_rate = inflation_rate
    super(amount: base_amount)
  end
  
  def amount_for_period(context)
    years = context.years_since_start
    @base_amount * ((1 + @inflation_rate) ** years)
  end
  
  def active?(context)
    true  # Always need to eat!
  end
end

# ============================================================================
# TRANSFERS - Special type of flow between assets
# ============================================================================

class Transfer
  attr_reader :from_asset, :to_asset, :amount
  
  def initialize(from:, to:, amount:)
    @from_asset = from
    @to_asset = to
    @amount = amount
  end
  
  def execute
    actual_amount = @from_asset.withdraw(@amount)
    @to_asset.deposit(actual_amount)
    actual_amount
  end
  
  def tax_implications
    # Transfers have tax consequences
    raise NotImplementedError
  end
end

class RothConversion < Transfer
  def initialize(from_traditional:, to_roth:, amount:)
    super(from: from_traditional, to: to_roth, amount: amount)
  end
  
  def tax_implications
    {
      ordinary_income: @amount,  # Pay tax on converted amount
      capital_gains: 0
    }
  end
end

class Rebalancing < Transfer
  def tax_implications
    # Depends on account types and gains
    if @from_asset.is_a?(TaxableAccount)
      @from_asset.tax_on_withdrawal(@amount)
    else
      { ordinary_income: 0, capital_gains: 0 }
    end
  end
end

# ============================================================================
# PEOPLE - Who owns what and receives what
# ============================================================================

class Person
  attr_reader :name, :date_of_birth, :role
  
  def initialize(name:, date_of_birth:, role: :primary)
    @name = name
    @date_of_birth = Date.parse(date_of_birth)
    @role = role  # :primary, :spouse, :dependent
  end
  
  def age_in_year(year)
    year - @date_of_birth.year
  end
  
  def alive_in_year?(year)
    # For now, assume always alive
    # Future: mortality tables, user-specified death year
    true
  end
end

# ============================================================================
# HOUSEHOLD - The organizing unit
# ============================================================================

class Household
  attr_reader :members, :assets, :income_flows, :expense_flows, :filing_status
  
  def initialize(members:, filing_status: :mfj)
    @members = members
    @assets = []
    @income_flows = []
    @expense_flows = []
    @filing_status = filing_status
  end
  
  def add_asset(asset)
    @assets << asset
  end
  
  def add_income(flow)
    @income_flows << flow
  end
  
  def add_expense(flow)
    @expense_flows << flow
  end
  
  def net_worth
    @assets.sum(&:balance)
  end
  
  def total_income_for_year(context)
    @income_flows.sum { |flow| flow.amount_for_period(context) }
  end
  
  def total_expenses_for_year(context)
    @expense_flows.sum { |flow| flow.amount_for_period(context) }
  end
  
  def assets_owned_by(person)
    @assets.select { |a| a.owner == person.name }
  end
  
  def joint_assets
    @assets.select { |a| a.owner == 'joint' }
  end
end

# ============================================================================
# SIMULATION CONTEXT - The running simulation state
# ============================================================================

class SimulationContext
  attr_reader :current_year, :start_year, :household
  
  def initialize(household:, start_year:)
    @household = household
    @start_year = start_year
    @current_year = start_year
  end
  
  def advance_year
    @current_year += 1
  end
  
  def years_since_start
    @current_year - @start_year
  end
  
  def age_of(person_name)
    person = @household.members.find { |m| m.name == person_name }
    person.age_in_year(@current_year)
  end
  
  def primary_person
    @household.members.find { |m| m.role == :primary }
  end
  
  def spouse
    @household.members.find { |m| m.role == :spouse }
  end
end

# ============================================================================
# STRATEGY - How to make decisions
# ============================================================================

class ConversionStrategy
  def decide_conversion_amount(context)
    raise NotImplementedError
  end
end

class DoNothingStrategy < ConversionStrategy
  def decide_conversion_amount(context)
    0  # Never convert
  end
end

class FillToBracketStrategy < ConversionStrategy
  attr_reader :target_income
  
  def initialize(target_income:)
    @target_income = target_income
  end
  
  def decide_conversion_amount(context)
    current_taxable_income = calculate_current_taxable(context)
    headroom = @target_income - current_taxable_income
    
    # Find available Traditional IRA balance
    trad_accounts = context.household.assets.select { |a| a.is_a?(TraditionalIRA) }
    available = trad_accounts.sum(&:balance)
    
    [headroom, 0, available].sort[1]  # Middle value (clamp to 0..available)
  end
  
  private
  
  def calculate_current_taxable(context)
    # Complex calculation of current year's taxable income
    # before any discretionary conversion
  end
end
```

### Key Design Decisions

**1. Two-Layer Hierarchy**
- Abstract base classes: `Asset`, `Flow`, `Transfer`
- Concrete implementations: `TraditionalIRA`, `SocialSecurityIncome`, `RothConversion`

**2. Assets Know Their Tax Rules**
- Each account type knows how withdrawals are taxed
- Prevents spreading tax logic throughout codebase
- Easy to add new account types

**3. Flows Know When They're Active**
- `active?(context)` - is this flow happening this year?
- `amount_for_period(context)` - how much this year?
- Context provides all needed info (year, ages, etc.)

**4. Clear Ownership Model**
- Assets have `owner` (person name or 'joint')
- Flows have `recipient` (who receives income) or are household-level (expenses)
- Enables multi-person households naturally

**5. Strategies are Objects**
- Not just parameters, but first-class objects
- Can have complex internal logic
- Easy to add new strategies

**6. Context Object Pattern**
- `SimulationContext` carries state through simulation
- Prevents passing 10 parameters to every method
- Clean, testable, comprehensible

### What This Enables

✅ **Multi-person households** - naturally supported
✅ **New asset types** - just subclass `Asset`
✅ **New income sources** - just subclass `IncomeFlow`  
✅ **Complex strategies** - just subclass `ConversionStrategy`
✅ **Testing** - each class is independently testable
✅ **Comprehension** - domain concepts map to code objects

### Migration Path

**Phase 1**: Create new classes alongside current code
**Phase 2**: Migrate one feature at a time (start with Assets)
**Phase 3**: Migrate Flows
**Phase 4**: Migrate Strategies
**Phase 5**: Delete old procedural code

**Don't rewrite everything at once!** Incremental migration keeps the app working.

---

## 🌟 Fully-Baked Ideas (Ready to Implement)

### Scenario Comparison System
**Vision**: Users can create, name, and visually compare multiple scenarios side-by-side.

**Implementation Path**:
- Store scenarios in memory during session (array of scenario objects)
- Each scenario has: name, profile snapshot, results
- UI shows 2-4 scenarios in grid, highlighting differences
- Add/Remove scenario buttons
- "Clone this scenario" to iterate on variations
- Visual diff: color-code metrics (green = better, red = worse)

**Why Joyful**: Makes decision-making tangible. Seeing "Retire at 65 vs 67" side-by-side transforms abstract numbers into clear choices.

---

### Comprehensive Profile & Simulation Editor
**Current Issue**: Parameters scattered between hardcoded values, profile.yml, and limited UI editor

**Solution - Two Clear Editors**:

#### 1. Profile Editor (Who You Are)
Fixed characteristics that don't change between scenarios:
- Personal: DOB, name
- Accounts: All balances and types
- Income Sources: Social Security PIA, pension amounts
- Tax Status: Filing status, state

#### 2. Simulation Editor (What You're Testing)
Strategy variables that differ between scenarios:
- Conversion strategy & parameters (ceiling amount)
- Years to simulate
- Growth rate assumptions
- Inflation rate
- Expense levels
- Claiming ages for SS
- RMD start age (if testing rule changes)

**Why Joyful**: Clear mental model. "This is me" vs "This is what I'm exploring."

---

### Tax Calculation Clarity
**Limitations to Surface**:

1. **Capital Gains Stacking** (Current Simplification)
   - UI Note: "Capital gains taxes use simplified calculation"
   - Code Comment: Explain that proper stacking considers ordinary income pushing CG into higher brackets
   - Planning Doc Note: Future enhancement would implement proper 0%/15%/20% threshold calculation

2. **SS Taxation Iteration** (Current Approximation)
   - UI Note: "Roth conversions may affect Social Security taxation. Actual headroom may vary slightly."
   - Code Comment: Explain that provisional income calculation should be iterative
   - Planning Doc Note: Implement iterative solver for optimal conversion amount

3. **State Taxes** (Currently Absent)
   - UI Note: "Federal taxes only. Consult tax professional for state impact."
   - Planning Doc: State tax engine is Phase 2

**Why Joyful**: Honesty builds trust. Users make better decisions when they understand the model's boundaries.

---

## 🌱 Half-Baked Ideas (Needs More Thought)

### Visual Timeline View
- Horizontal timeline showing major life events
- Mark when RMDs start, SS claimed, conversions happen
- Drag events to see impact?
- **Question**: Does this add clarity or complexity?

### Tax Bracket Visualization
- Show where you sit in brackets each year
- Highlight "headroom" visually
- **Question**: Is this the right level of detail for "simple"?

### Portfolio Allocation Editor
- Currently growth rates are account-type based
- Could allow per-account asset allocation
- **Tension**: More realistic vs. more complex

### Batch Scenario Generator
- "Show me: no conversion, convert to 12%, convert to 22%, convert to 24%"
- Auto-generate common comparisons
- **Appeal**: Fast exploration
- **Concern**: Overwhelm with options?

---

## 🫧 Effervescent Ideas (Raw, Exciting, Uncertain)

### Optimization Engine
- "Find me the optimal conversion strategy"
- Maximize: net worth? minimize taxes? maximize legacy?
- **Exciting** because it answers "what should I do?"
- **Uncertain** because it might undermine user agency and understanding

### Monte Carlo Uncertainty
- Show range of outcomes based on market volatility
- "Your ending net worth could be $X to $Y"
- **Exciting** because it's realistic
- **Uncertain** because it adds cognitive load

### Natural Language Insights
- "Your strategy saves $X in taxes over 30 years, primarily by..."
- Auto-generated summary of key findings
- **Exciting** because it aids comprehension
- **Uncertain** because it might feel patronizing

### Collaborative Scenarios
- Share scenario link with spouse/advisor
- Comments on scenarios
- **Exciting** for real-world planning
- **Uncertain** about infrastructure needs

---

## 📊 Income Sources & Tax Rules Inventory

### Currently Implemented

#### Social Security
**Behavior**:
- Starts at claiming age
- Fixed annual amount (PIA)
- Taxation via provisional income calculation
  - Phase 1: Income $32k-44k → 50% taxable
  - Phase 2: Income $44k+ → 85% taxable

**Simplifications**:
- No COLA adjustments
- No reduction for early claiming
- No delayed retirement credits
- Provisional income calculation is approximate (should iterate)

**Missing Nuances**:
- Spousal benefits
- Survivor benefits
- Earnings test (if working before FRA)
- WEP/GPO for public pensions

---

#### Required Minimum Distributions (RMDs)
**Behavior**:
- Starts at age 73
- Uses IRS Uniform Lifetime Table
- Forced withdrawal from Traditional IRA
- Fully taxable as ordinary income

**Simplifications**:
- Fixed age 73 (should vary by birth year)
- No beneficiary age adjustments
- No penalty handling for missed RMDs

**Missing Nuances**:
- Inherited IRA rules
- QCDs (Qualified Charitable Distributions)
- Multiple account aggregation rules

---

#### Capital Gains from Taxable Accounts
**Behavior**:
- Generated when withdrawals exceed cost basis
- Cost basis fraction per account
- Taxed at preferential rates (0%/15%/20%)

**Simplifications**:
- Simplified rate calculation (doesn't properly stack)
- No short-term vs long-term distinction
- No tax loss harvesting
- No specific lot identification

**Missing Nuances**:
- Net Investment Income Tax (NIIT) 3.8%
- State capital gains tax
- Step-up basis at death
- Dividend income vs capital gains

---

### Not Yet Implemented

#### Pensions
**Should Include**:
- Start age
- Annual amount
- COLA adjustments (fixed % or CPI)
- Survivor benefit options
- Taxation (fully taxable ordinary income)

**Complexity Level**: Low - similar to SS structure

---

#### Employment Income (W-2/1099)
**Should Include**:
- Annual salary/wages
- Start/end years
- Retirement contributions (401k, etc.)
- Impact on SS earnings test
- FICA taxes

**Complexity Level**: Medium - affects contribution room

---

#### Rental Income
**Should Include**:
- Gross rental income
- Deductible expenses
- Depreciation
- Passive activity loss rules

**Complexity Level**: High - tax treatment is complex

---

#### Annuities
**Should Include**:
- Immediate vs deferred
- Fixed vs variable
- Payout amount and duration
- Exclusion ratio for taxation

**Complexity Level**: Medium - diverse products

---

#### Investment Dividends & Interest
**Should Include**:
- Qualified vs ordinary dividends
- Tax-exempt interest (municipal bonds)
- Annual amounts or rates

**Complexity Level**: Low-Medium

---

#### Part-Time Work in Retirement
**Should Include**:
- Income amount
- Years active
- SS earnings test impact
- Continued retirement contributions

**Complexity Level**: Medium

---

## 🎯 Recommended Implementation Plan

### Phase 1: Foundation (Current Sprint)
1. ✅ Add comprehensive test coverage
2. ✅ Fix profile round-trip consistency
3. ✅ Implement Chart.js for visualization
4. ✅ Add UI clarity notes about limitations
5. ✅ Create scenario comparison framework

### Phase 2: Income Sources (Next)
**Priority Order** (by frequency of use + implementation simplicity):

1. **Pensions** - High frequency, low complexity
2. **Dividends/Interest** - Very common, low complexity  
3. **Part-Time Work** - Common for early retirees, medium complexity
4. **Employment Income** - Important for pre-retirement planning, medium complexity

**Implementation Approach**:
- Create unified `IncomeSource` concept
- Each type knows its taxation rules
- Each type knows when it's active (age ranges, year ranges)
- Simulator iterates through all sources generically

### Phase 3: Tax Sophistication
1. Iterative SS provisional income calculation
2. Proper capital gains stacking
3. NIIT (3.8% on investment income)
4. Basic state tax engine (handful of states)

### Phase 4: User Empowerment
1. Multi-scenario comparison UI
2. Scenario naming and management
3. Export/print capabilities
4. Guided "first time user" flow

---

## 🎨 Design Principles for All Additions

### The "Simplicity Test"
Before adding any feature, ask:
1. Does this serve the core purpose?
2. Can a user understand it in 30 seconds?
3. Does it add more clarity than complexity?
4. Would a financial advisor find this useful?

### The "Joy Test"  
Before adding any feature, ask:
1. Does this make the code more or less readable?
2. Will future maintainers smile or frown?
3. Does it follow the Principle of Least Astonishment?
4. Can it be implemented with elegant Ruby?

### The "Honesty Test"
Before adding any feature, ask:
1. Are we clear about its limitations?
2. Does it oversimplify in dangerous ways?
3. Would a tax professional approve?
4. Do users understand what it does and doesn't do?

---

## 📝 Open Questions

1. **Scenario Storage**: Keep in-memory only or add export/import?
2. **Mobile Experience**: Should this work well on phones?
3. **Advisor Mode**: Different UI for professional use?
4. **Data Persistence**: When does ephemerality become frustration?
5. **Educational Content**: Inline help vs separate docs?

---

## 🌈 The North Star

Simple Foresight exists to make one thing crystal clear: **the long-term financial impact of strategic Roth conversions**.

Every feature should serve this purpose. Every line of code should bring joy. Every user should leave with clarity and confidence.

When in doubt, choose:
- Clarity over cleverness
- Simplicity over sophistication  
- Honesty over perfection
- Joy over completeness

---

*Last Updated: October 2025*
*Next Review: After Phase 1 completion*