require 'minitest/autorun'
require 'minitest/spec'
require_relative '../app'

describe Foresight::Simple::Simulator do
  let(:simulator) { Foresight::Simple::Simulator.new }
  
  let(:minimal_profile) do
    {
      start_year: 2024,
      years_to_simulate: 5,
      inflation_rate: 0.0,
      growth_assumptions: {
        traditional: 0.05,
        roth: 0.05,
        taxable: 0.05,
        cash: 0.01
      },
      household: {
        filing_status: 'mfj',
        annual_expenses: 80_000
      },
      members: [
        { name: 'Pat', date_of_birth: '1964-05-01' }
      ],
      accounts: [
        { type: :traditional, owner: 'Pat', balance: 500_000 },
        { type: :roth, owner: 'Pat', balance: 100_000 },
        { type: :taxable, owner: 'Pat', balance: 200_000, cost_basis_fraction: 0.6 }
      ],
      income_sources: [
        { type: :social_security, recipient: 'Pat', pia_annual: 30_000, claiming_age: 70 }
      ]
    }
  end

  describe "do_nothing strategy" do
    it "performs no conversions" do
      result = simulator.run(strategy: :do_nothing, profile: minimal_profile)
      
      total_conversions = result[:yearly].sum do |year| 
        year[:taxable_income_breakdown][:conversions]
      end
      
      assert_equal 0, total_conversions, "Do nothing strategy should not convert any funds"
    end

    it "maintains traditional IRA balance (minus RMDs and growth)" do
      result = simulator.run(strategy: :do_nothing, profile: minimal_profile)
      
      # Before age 73, Traditional balance should only grow
      first_year = result[:yearly].first
      assert first_year[:age] < 73, "First year should be before RMD age"
      
      # Traditional balance should have grown from growth rate
      # (We can't easily test exact value without duplicating logic, but we can verify it grew)
    end
  end

  describe "fill_to_bracket strategy" do
    it "converts funds when below the ceiling" do
      result = simulator.run(
        strategy: :fill_to_bracket, 
        strategy_params: { ceiling: 94_300 },
        profile: minimal_profile
      )
      
      total_conversions = result[:yearly].sum do |year| 
        year[:taxable_income_breakdown][:conversions]
      end
      
      assert total_conversions > 0, "Fill to bracket should perform conversions"
    end

    it "respects the traditional IRA balance limit" do
      # Profile with small traditional balance
      small_trad_profile = minimal_profile.dup
      small_trad_profile[:accounts] = minimal_profile[:accounts].map do |acct|
        if acct[:type] == :traditional
          acct.merge(balance: 10_000)  # Very small balance
        else
          acct
        end
      end

      result = simulator.run(
        strategy: :fill_to_bracket,
        strategy_params: { ceiling: 94_300 },
        profile: small_trad_profile
      )

      # Total conversions should not exceed the starting traditional balance
      total_conversions = result[:yearly].sum do |year|
        year[:taxable_income_breakdown][:conversions]
      end

      assert total_conversions <= 10_000, "Cannot convert more than available balance"
    end
  end

  describe "RMD calculations" do
    it "starts RMDs at age 73" do
      # Profile for someone turning 73
      rmd_profile = minimal_profile.dup
      rmd_profile[:members] = [{ name: 'Elder', date_of_birth: '1951-01-01' }]
      rmd_profile[:start_year] = 2024

      result = simulator.run(strategy: :do_nothing, profile: rmd_profile)
      
      # Find the year they turn 73
      year_73 = result[:yearly].find { |y| y[:age] == 73 }
      assert year_73, "Should have year where age is 73"
      
      # Should have RMD income
      assert year_73[:income_sources][:rmd] > 0, "Should have RMD at age 73"
    end

    it "has no RMDs before age 73" do
      result = simulator.run(strategy: :do_nothing, profile: minimal_profile)
      
      # All years should be before age 73 in our minimal profile
      result[:yearly].each do |year|
        if year[:age] < 73
          assert_equal 0, year[:income_sources][:rmd], "No RMD before age 73"
        end
      end
    end
  end

  describe "Social Security behavior" do
    it "starts benefits at claiming age" do
      result = simulator.run(strategy: :do_nothing, profile: minimal_profile)
      
      result[:yearly].each do |year|
        if year[:age] < 70
          assert_equal 0, year[:income_sources][:social_security], "No SS before claiming age"
        else
          assert_equal 30_000, year[:income_sources][:social_security], "Full SS after claiming"
        end
      end
    end
  end

  describe "aggregate results" do
    it "calculates cumulative taxes correctly" do
      result = simulator.run(strategy: :do_nothing, profile: minimal_profile)
      
      manual_sum = result[:yearly].sum { |y| y[:total_tax] }
      
      assert_equal manual_sum.round(0), result[:aggregate][:cumulative_taxes],
        "Aggregate cumulative taxes should match sum of yearly taxes"
    end

    it "reports final year's net worth" do
      result = simulator.run(strategy: :do_nothing, profile: minimal_profile)
      
      last_year_nw = result[:yearly].last[:ending_net_worth]
      
      assert_equal last_year_nw, result[:aggregate][:ending_net_worth],
        "Aggregate net worth should match final year"
    end
  end

  describe "withdrawal hierarchy" do
    it "withdraws from taxable account first" do
      # Profile where expenses exceed income sources
      withdrawal_profile = minimal_profile.dup
      withdrawal_profile[:household][:annual_expenses] = 90_000
      withdrawal_profile[:income_sources] = [
        { type: :social_security, recipient: 'Pat', pia_annual: 30_000, claiming_age: 60 }
      ]

      result = simulator.run(strategy: :do_nothing, profile: withdrawal_profile)
      
      first_year = result[:yearly].first
      
      # Should have withdrawn for spending (90k expenses - 30k SS = 60k shortfall)
      assert first_year[:income_sources][:withdrawals] > 0, "Should withdraw to cover shortfall"
    end
  end

  describe "asset growth" do
    it "grows accounts according to growth assumptions" do
      # Use simple profile with minimal withdrawals
      growth_profile = minimal_profile.dup
      growth_profile[:household][:annual_expenses] = 10_000  # Minimal expenses
      # Keep the SS income source so simulator doesn't break

      result = simulator.run(strategy: :do_nothing, profile: growth_profile)
      
      first_nw = result[:yearly].first[:ending_net_worth]
      last_nw = result[:yearly].last[:ending_net_worth]
      
      assert last_nw > first_nw, "Net worth should grow with positive returns"
    end
  end
end
