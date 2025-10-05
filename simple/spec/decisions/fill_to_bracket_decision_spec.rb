require 'bundler/setup'
Bundler.require(:default, :test)

require 'minitest/autorun'
require_relative '../../app'

class FillToBracketDecisionSpec < Minitest::Test
  Decision = Foresight::Simple::Decisions::FillToBracketDecision


  def tax_brackets
    tb = Foresight::Simple::TAX_BRACKETS
    applicable_year = tb.keys.select { |y| y <= 2024 }.max || tb.keys.min
    tb[applicable_year]
  end

  def test_returns_zero_when_headroom_non_positive
  accounts = [TraditionalIRA.new(balance: 50_000, owner: 'Pat')]
    amount = Decision.propose_conversion_amount(
      rmd: 40_000,
      ss_benefit: 0,
      spending_withdrawals: [{ taxable_ordinary: 60_000 }],
      tax_brackets: tax_brackets,
      accounts: accounts,
      ceiling: 100_000
    )
    assert_equal 0, amount
  end

  def test_caps_by_traditional_balance
    amount = Decision.propose_conversion_amount(
      rmd: 10_000,
      ss_benefit: 0,
      spending_withdrawals: [{ taxable_ordinary: 5_000 }],
      tax_brackets: tax_brackets,
  accounts: [TraditionalIRA.new(balance: 7_500, owner: 'Pat')],
      ceiling: 50_000
    )
    assert_equal 7_500, amount
  end

  def test_taxable_social_security_reduces_headroom
    amount_no_ss = Decision.propose_conversion_amount(
      rmd: 0,
      ss_benefit: 0,
      spending_withdrawals: [],
      tax_brackets: tax_brackets,
  accounts: [TraditionalIRA.new(balance: 100_000, owner: 'Pat')],
      ceiling: 30_000
    )

    amount_with_ss = Decision.propose_conversion_amount(
      rmd: 0,
      ss_benefit: 80_000,
      spending_withdrawals: [],
      tax_brackets: tax_brackets,
  accounts: [TraditionalIRA.new(balance: 100_000, owner: 'Pat')],
      ceiling: 30_000
    )

    assert amount_with_ss < amount_no_ss, 'Taxable SS should reduce headroom and thus conversion amount'
  end
end
