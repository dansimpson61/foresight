require 'minitest/autorun'
require 'minitest/spec'
require_relative '../../lib/roth_ira'

describe RothIRA do
  it 'treats withdrawals as tax-free in this simplified model' do
    roth = RothIRA.new(balance: 50_000, owner: 'Pat')
    taxes = roth.tax_on_withdrawal(5_000)
    _(taxes[:ordinary_income]).must_equal 0
    _(taxes[:capital_gains]).must_equal 0
  end

  it 'has no RMDs' do
    roth = RothIRA.new(balance: 50_000, owner: 'Pat')
    _(roth.rmd_required?(80)).must_equal false
  end
end
