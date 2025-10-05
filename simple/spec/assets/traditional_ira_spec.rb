require 'minitest/autorun'
require 'minitest/spec'
require_relative '../../lib/traditional_ira'

describe TraditionalIRA do
  it 'treats withdrawals as ordinary income' do
    ira = TraditionalIRA.new(balance: 100_000, owner: 'Pat')
    taxes = ira.tax_on_withdrawal(10_000)
    _(taxes[:ordinary_income]).must_equal 10_000
    _(taxes[:capital_gains]).must_equal 0
  end

  it 'requires RMD at age 73 and above' do
    ira = TraditionalIRA.new(balance: 100_000, owner: 'Pat')
    _(ira.rmd_required?(72)).must_equal false
    _(ira.rmd_required?(73)).must_equal true
  end

  it 'calculates RMD with divisor table' do
    ira = TraditionalIRA.new(balance: 100_000, owner: 'Pat')
    rmd = ira.calculate_rmd(73)
    _(rmd).must_be_close_to (100_000 / 26.5), 0.01
  end
end
