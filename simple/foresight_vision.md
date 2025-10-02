# Simple Foresight: Living Vision & Planning

*A living document in the spirit of joyful development*

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