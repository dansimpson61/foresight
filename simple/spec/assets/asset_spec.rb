require 'minitest/autorun'
require 'minitest/spec'
require_relative '../../lib/asset'
require_relative '../../lib/traditional_ira'
require_relative '../../lib/roth_ira'
require_relative '../../lib/taxable_account'

describe Asset do
  it 'grows by rate' do
    a = RothIRA.new(balance: 1000, owner: 'Pat')
    a.grow(0.10)
    _(a.balance).must_be_close_to 1100, 0.001
  end

  it 'withdraws up to available balance' do
    a = TaxableAccount.new(balance: 500, owner: 'Pat', cost_basis_fraction: 0.8)
    pulled = a.withdraw(700)
    _(pulled).must_equal 500
    _(a.balance).must_equal 0
  end
end
