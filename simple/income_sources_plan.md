# Income Sources: Comprehensive Inventory & Implementation Plan

*In the spirit of joyful simplicity and completeness*

## Current State: What We Have

### 1. Social Security Benefits ✅
**Implementation Status**: Basic functionality present

**Current Behavior**:
- Starts at claiming age (user-configurable)
- Fixed annual amount (PIA)
- Taxation via provisional income calculation

**Present Rules**:
- ✅ Basic claiming age logic (age >= claiming_age)
- ✅ Provisional income calculation for taxation
- ✅ Phase 1: 50% taxable above $32k (MFJ)
- ✅ Phase 2: 85% taxable above $44k (MFJ)

**Absent/Simplified Rules**:
- ❌ COLA (Cost of Living Adjustments) - assumes constant dollars
- ❌ Early claiming reduction (before FRA)
- ❌ Delayed retirement credits (after FRA, up to age 70)
- ❌ Spousal benefits
- ❌ Survivor benefits
- ❌ WEP/GPO (Windfall Elimination Provision / Government Pension Offset)
- ❌ Earnings test (if working before FRA)
- ⚠️ Provisional income iteration (simplified, not iterative)

**Joyful Path Forward**:
```ruby
class SocialSecurityBenefit
  # Current simplified model
  def annual_benefit(age, claiming_age, pia)
    age >= claiming_age ? pia : 0.0
  end
  
  # Enhanced model (Phase 2)
  def annual_benefit_with_adjustments(age, claiming_age, fra, pia)
    return 0.0 if age < claiming_age
    
    # Apply reduction for early claiming or credits for delay
    if claiming_age < fra
      # Roughly 6.7% reduction per year before FRA (simplified)
      reduction_factor = 1 - ((fra - claiming_age) * 0.067)
      pia * reduction_factor
    elsif claiming_age > fra && claiming_age <= 70
      # 8% increase per year of delay after FRA
      credit_factor = 1 + ((claiming_age - fra) * 0.08)
      pia * credit_factor
    else
      pia
    end
  end
end
```

---

### 2. Required Minimum Distributions (RMDs) ✅
**Implementation Status**: Functional with known simplifications

**Current Behavior**:
- Starts at age 73 (hardcoded)
- Uses IRS Uniform Lifetime Table
- Automatically withdraws from Traditional IRA
- Fully taxable as ordinary income

**Present Rules**:
- ✅ Age-based divisor table (73-100+)
- ✅ Automatic calculation based on prior year-end balance
- ✅ Full taxation as ordinary income
- ✅ Reduces Traditional IRA balance

**Absent Rules**:
- ❌ Birth year variations (age 73 vs 75 based on DOB)
- ❌ Beneficiary designations affecting divisor
- ❌ RMD aggregation across multiple IRAs
- ❌ Penalty calculation for missed RMDs (50% excise tax)
- ❌ QCDs (Qualified Charitable Distributions) as alternative
- ❌ Still-working exception

**Joyful Path Forward**:
```ruby
def rmd_start_age(date_of_birth)
  # SECURE Act 2.0 rules
  birth_year = Date.parse(date_of_birth).year
  case birth_year
  when ...1951 then 72
  when 1951..1959 then 73
  else 75
  end
end

# Already have good divisor table - just add birth year logic
```

---

### 3. Capital Gains from Withdrawals ✅
**Implementation Status**: Basic but overly simplified

**Current Behavior**:
- Generated when taxable account withdrawals exceed cost basis
- Single cost_basis_fraction per account
- Preferential tax rates (simplified)

**Present Rules**:
- ✅ Cost basis tracking per account
- ✅ Capital gains calculation on withdrawals
- ⚠️ Preferential rates (0%/15%/20%) - simplified stacking

**Absent Rules**:
- ❌ Short-term vs long-term distinction
- ❌ Proper stacking of CG on top of ordinary income
- ❌ NIIT (Net Investment Income Tax) - 3.8% on investment income
- ❌ Tax loss harvesting
- ❌ Specific lot identification (FIFO/LIFO/SpecID)
- ❌ Step-up basis at death
- ❌ Wash sale rules
- ❌ State capital gains tax

**Joyful Path Forward**:
```ruby
def calculate_capital_gains_tax(cg_amount, ordinary_income, filing_status)
  # Proper stacking: CG rates depend on where ordinary income puts you
  brackets = CAPITAL_GAINS_BRACKETS[filing_status]
  
  # Available space in 0% bracket
  space_in_zero = [brackets[:tier1_ceiling] - ordinary_income, 0].max
  cg_at_zero = [cg_amount, space_in_zero].min
  
  # Available space in 15% bracket  
  remaining_cg = cg_amount - cg_at_zero
  space_in_fifteen = [brackets[:tier2_ceiling] - (ordinary_income + cg_at_zero), 0].max
  cg_at_fifteen = [remaining_cg, space_in_fifteen].min
  
  # Everything else at 20%
  cg_at_twenty = remaining_cg - cg_at_fifteen
  
  (cg_at_zero * 0) + (cg_at_fifteen * 0.15) + (cg_at_twenty * 0.20)
end

# Add NIIT separately
def niit(investment_income, agi, magi_threshold)
  return 0 if agi <= magi_threshold
  excess = agi - magi_threshold
  [investment_income, excess].min * 0.038
end
```

---

## Not Yet Implemented: What We Need

### 4. Pensions 🎯 **HIGH PRIORITY**
**Why**: Very common, simple to implement, high value

**Behavior**:
- Fixed annual payment starting at retirement age
- Optional COLA adjustments
- Survivor benefit options
- Fully taxable as ordinary income

**Rules Needed**:
- Start age
- Annual amount
- COLA rate (0%, fixed %, or CPI-linked)
- End conditions (lifetime, period certain, joint & survivor)

**Joyful Implementation**:
```ruby
# In profile.yml
income_sources:
  - type: :pension
    recipient: 'Pat'
    annual_amount: 50000
    start_age: 65
    cola_rate: 0.02  # 2% annual increase
    survivor_percentage: 0.5  # 50% to survivor
    taxation: :fully_taxable

# In simulator
def get_pension_benefit(pension_source, age, start_year, current_year)
  return 0.0 if age < pension_source[:start_age]
  
  years_elapsed = current_year - start_year
  base_amount = pension_source[:annual_amount]
  
  # Apply COLA
  base_amount * ((1 + pension_source[:cola_rate]) ** years_elapsed)
end
```

**Complexity**: LOW - mirrors Social Security structure

---

### 5. Dividends & Interest 🎯 **HIGH PRIORITY**
**Why**: Nearly universal, affects taxable income, relatively simple

**Behavior**:
- Generated annually from investment accounts
- Qualified dividends get preferential rates
- Ordinary dividends/interest at ordinary rates
- Can be reinvested or distributed

**Rules Needed**:
- Dividend yield per account
- Qualified vs ordinary percentage
- Interest-bearing account yields
- Tax-exempt interest (municipal bonds)

**Joyful Implementation**:
```ruby
# Enhanced account structure
accounts:
  - type: :taxable
    balance: 500000
    cost_basis_fraction: 0.6
    dividend_yield: 0.02  # 2% annual dividends
    qualified_dividend_percentage: 0.80  # 80% are qualified
    interest_yield: 0.01  # 1% interest from bonds

# In simulator  
def calculate_investment_income(account, year_start_balance)
  dividends = year_start_balance * account[:dividend_yield]
  interest = year_start_balance * account[:interest_yield]
  
  qualified_div = dividends * account[:qualified_dividend_percentage]
  ordinary_div = dividends - qualified_div
  
  {
    qualified_dividends: qualified_div,
    ordinary_dividends: ordinary_div,
    interest: interest,
    total_investment_income: dividends + interest
  }
end
```

**Complexity**: LOW-MEDIUM - integrates with existing capital gains logic

---

### 6. Employment Income (W-2) 🎯 **MEDIUM PRIORITY**
**Why**: Important for pre-retirement planning, enables contribution modeling

**Behavior**:
- Annual salary/wages
- Subject to payroll taxes (FICA)
- Enables 401(k)/IRA contributions
- Affects Social Security earnings test if before FRA

**Rules Needed**:
- Salary amount
- Start/end years
- 401(k) contribution rate
- Employer match
- FICA calculations
- SS earnings test interaction

**Joyful Implementation**:
```ruby
income_sources:
  - type: :employment
    recipient: 'Pat'
    annual_salary: 150000
    start_year: 2024
    end_year: 2030  # Plans to retire
    k401_contribution_rate: 0.15
    employer_match_rate: 0.05
    employer_match_cap: 0.06  # Match up to 6% of salary

def get_employment_income(emp_source, current_year, age)
  return nil if current_year < emp_source[:start_year]
  return nil if current_year > emp_source[:end_year]
  
  salary = emp_source[:annual_salary]
  employee_contrib = salary * emp_source[:k401_contribution_rate]
  employer_match = salary * [emp_source[:employer_match_rate], 
                               emp_source[:employer_match_cap]].min
  
  # Reduce taxable income by pre-tax 401k contributions
  taxable_wages = salary - employee_contrib
  fica_tax = calculate_fica(salary)
  
  {
    gross_salary: salary,
    taxable_wages: taxable_wages,
    employee_401k: employee_contrib,
    employer_401k: employer_match,
    fica: fica_tax,
    affects_ss_earnings_test: age < 67
  }
end
```

**Complexity**: MEDIUM - touches multiple systems (taxes, contributions, accounts)

---

### 7. Part-Time Retirement Work 🎯 **MEDIUM PRIORITY**
**Why**: Very common scenario, affects planning significantly

**Behavior**:
- Similar to employment but usually lower amounts
- May trigger SS earnings test
- May enable continued retirement contributions
- Often temporary (few years)

**Rules Needed**:
- Annual income amount
- Start/end ages or years
- Whether continuing retirement contributions
- Integration with SS earnings test

**Joyful Implementation**:
```ruby
income_sources:
  - type: :part_time_work
    recipient: 'Pat'
    annual_income: 30000
    start_age: 65
    end_age: 68
    enables_ira_contribution: true

# Very similar to employment but simpler
# Can reuse much of employment logic with fewer complications
```

**Complexity**: MEDIUM - needs SS earnings test logic

---

### 8. Rental Income ⚠️ **LOWER PRIORITY**
**Why**: Less common, much more complex tax treatment

**Behavior**:
- Gross rental income
- Deductible expenses (maintenance, property tax, insurance)
- Depreciation deductions
- Passive activity loss rules
- May be subject to NIIT

**Rules Needed**:
- Properties and their income
- Expense tracking
- Depreciation schedules
- Active vs passive participation
- At-risk and passive activity rules

**Complexity**: HIGH - tax treatment is very complex

**Recommendation**: Phase 3 or later. Most users can approximate as "other income"

---

### 9. Annuities ⚠️ **LOWER PRIORITY**  
**Why**: Less common, product-specific complexity

**Behavior**:
- Immediate vs deferred
- Fixed vs variable payouts
- Period certain vs lifetime
- Exclusion ratio for taxation (return of principal vs earnings)

**Rules Needed**:
- Product type and terms
- Payout calculations
- Exclusion ratio
- Beneficiary provisions

**Complexity**: MEDIUM-HIGH - many product variations

**Recommendation**: Phase 3. Significant but not universal

---

### 10. Self-Employment Income ⚠️ **LOWER PRIORITY**
**Why**: Important niche but complex tax treatment

**Behavior**:
- Net business income
- Self-employment tax (both employer and employee FICA)
- QBI deduction (Qualified Business Income)
- SEP-IRA or Solo 401(k) contributions

**Complexity**: HIGH - requires business expense tracking, quarterly estimated taxes

**Recommendation**: Phase 3 or later

---

## Implementation Strategy: The Joyful Path

### Phase 1: Fix & Polish Current Sources (IMMEDIATE)
**Sprint Goal**: Make what we have excellent

1. ✅ Add comprehensive tests for SS, RMDs, CG
2. ✅ Fix capital gains stacking calculation
3. ✅ Add iterative SS provisional income solver
4. ✅ Document all simplifications clearly
5. ✅ Add birth-year-based RMD age logic

**Why First**: Trust comes from excellence in basics

---

### Phase 2: Universal Income Sources (NEXT - 2-3 weeks)
**Sprint Goal**: Cover 90% of users

**Add in Order**:
1. **Pensions** (3 days)
   - Simple structure, high impact
   - Test with various COLA scenarios
   
2. **Dividends & Interest** (4 days)
   - Enhances existing accounts
   - Enables realistic taxable account modeling
   - Adds qualified dividend logic
   
3. **Part-Time Work** (5 days)
   - Common retirement scenario
   - Requires SS earnings test
   - Enables IRA contribution modeling

**Deliverable**: App handles all common retirement income types

---

### Phase 3: Pre-Retirement Planning (FUTURE - 1-2 months)
**Sprint Goal**: Extend useful range to include working years

1. **Employment Income** (1 week)
   - Full W-2 modeling
   - 401(k) contributions
   - FICA taxes
   - Integration with retirement accounts
   
2. **Capital Gains Sophistication** (3 days)
   - Short-term vs long-term
   - NIIT (3.8% surtax)
   - Better stacking logic
   
3. **Enhanced SS Benefits** (4 days)
   - Early claiming reductions
   - Delayed retirement credits
   - Spousal benefits
   - Earnings test

**Deliverable**: App useful from age 50+ through retirement

---

### Phase 4: Advanced Scenarios (FUTURE - as needed)
**Only if user demand justifies complexity**

1. Rental Income
2. Annuities
3. Self-Employment
4. Inherited IRAs
5. HSA distributions
6. 529 distributions

---

## Architectural Pattern: Unified Income Source

**The Joyful Way**: All income sources follow the same contract

```ruby
class IncomeSource
  # Every source knows how to calculate its contribution
  def annual_amount(age:, year:, context:)
    raise NotImplementedError
  end
  
  # Every source knows its tax treatment
  def taxation_details(amount)
    raise NotImplementedError
  end
  
  # Every source knows when it's active
  def active?(age:, year:)
    raise NotImplementedError
  end
end

class SocialSecurityIncome < IncomeSource
  def annual_amount(age:, year:, context:)
    return 0 if age < @claiming_age
    apply_cola(@base_pia, year - @start_year)
  end
  
  def taxation_details(amount)
    { 
      type: :social_security,
      amount: amount,
      requires_provisional_income_calc: true 
    }
  end
  
  def active?(age:, year:)
    age >= @claiming_age
  end
end

class PensionIncome < IncomeSource
  def annual_amount(age:, year:, context:)
    return 0 if age < @start_age
    apply_cola(@annual_payment, year - @start_year)
  end
  
  def taxation_details(amount)
    { 
      type: :fully_taxable_ordinary,
      amount: amount 
    }
  end
  
  def active?(age:, year:)
    age >= @start_age
  end
end

# Simulator becomes beautifully simple
def calculate_income_for_year(age, year, profile)
  profile[:income_sources].sum do |source_config|
    source = build_income_source(source_config)
    source.active?(age: age, year: year) ? source.annual_amount(age: age, year: year) : 0
  end
end
```

**Why Joyful**:
- Single responsibility per class
- Easy to add new types
- Easy to test in isolation
- Clear contract
- Follows Ruby's duck typing naturally

---

## Testing Strategy

**For each new income source, test**:

1. **Activation Logic**
   - Doesn't pay before start condition
   - Pays at correct age/year
   - Handles edge cases (exactly at start age)

2. **Amount Calculation**
   - Base amount correct
   - COLA/adjustments work
   - Growth/changes over time

3. **Tax Treatment**
   - Correct characterization (ordinary, CG, etc.)
   - Special rules apply (SS provisional, etc.)
   - Integrates correctly with other income

4. **Integration**
   - Works with existing sources
   - Doesn't break other calculations
   - Profile round-trip works

---

## Success Criteria

**We'll know we've succeeded when**:

1. ✅ Every income source has >90% test coverage
2. ✅ Profile editor exposes all relevant parameters
3. ✅ Tax calculations are accurate within 5% of TurboTax
4. ✅ Code remains readable and joyful
5. ✅ New sources take < 1 day to add
6. ✅ Users can model their actual situation
7. ✅ Documentation is clear about what's included/excluded

---

## The North Star Reminder

> "We're building a tool to answer ONE question with clarity:
> What is the long-term financial impact of strategic Roth conversions?"

Every income source we add should serve this purpose. If it doesn't materially affect Roth conversion strategy, it can wait.

**Core Income Types for Roth Strategy**:
1. ✅ RMDs - directly affected by conversions
2. ✅ Social Security - taxation affected by provisional income
3. 🎯 Pensions - stable income affects headroom
4. 🎯 Dividends/Interest - affects taxable income floor
5. 🎯 Part-time work - affects income in conversion years

Everything else is nice-to-have but not essential to the core mission.

---

*Stay joyful. Stay focused. Add complexity only when it serves clarity.*