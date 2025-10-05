require 'minitest/autorun'
require 'minitest/spec'
require_relative '../../lib/traditional_ira'
require_relative '../../lib/roth_ira'
require_relative '../../lib/taxable_account'
require_relative '../../lib/policies/withdrawal_policy'

describe WithdrawalPolicy do
  it 'withdraws from taxable then traditional then roth' do
    taxable = TaxableAccount.new(balance: 10_000, owner: 'Pat', cost_basis_fraction: 0.6)
    trad = TraditionalIRA.new(balance: 5_000, owner: 'Pat')
    roth = RothIRA.new(balance: 2_000, owner: 'Pat')

    events = WithdrawalPolicy.withdraw_for_spending(12_000, [taxable, trad, roth])
    total = events.sum { |e| e[:amount] }

    _(total).must_equal 12_000
    _(taxable.balance).must_equal 0
    _(trad.balance).must_equal 3_000
    _(roth.balance).must_equal 2_000

    first_event_type = events.first
    _(first_event_type[:type]).must_equal :withdrawal
  end

  it 'handles partial withdrawal when shortfall exceeds balances' do
    taxable = TaxableAccount.new(balance: 1_000, owner: 'Pat', cost_basis_fraction: 0.6)
    events = WithdrawalPolicy.withdraw_for_spending(5_000, [taxable])
    total = events.sum { |e| e[:amount] }
    _(total).must_equal 1_000
  end
end
