require 'minitest/autorun'
require 'minitest/spec'
require_relative '../../lib/taxable_account'

describe TaxableAccount do
  it 'realizes capital gains based on cost basis fraction' do
    acct = TaxableAccount.new(balance: 100_000, owner: 'Pat', cost_basis_fraction: 0.6)
    taxes = acct.tax_on_withdrawal(10_000)
    _(taxes[:ordinary_income]).must_equal 0
    _(taxes[:capital_gains]).must_be_close_to 4000, 0.001
  end

  it 'withdraws reduces balance by actual amount pulled' do
    acct = TaxableAccount.new(balance: 5_000, owner: 'Pat', cost_basis_fraction: 0.6)
    pulled = acct.withdraw(2_000)
    _(pulled).must_equal 2_000
    _(acct.balance).must_equal 3_000
  end
end
