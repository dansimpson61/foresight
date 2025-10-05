require 'minitest/autorun'
require 'minitest/spec'
require_relative '../../lib/traditional_ira'
require_relative '../../lib/roth_ira'
require_relative '../../lib/flows/conversion_flow'

describe ConversionFlow do
  it 'moves funds from traditional to roth and is ordinary income' do
    t = TraditionalIRA.new(balance: 50_000, owner: 'Pat')
    r = RothIRA.new(balance: 5_000, owner: 'Pat')
    flow = ConversionFlow.new(amount: 10_000, from_account: t, to_account: r)
    _(flow.tax_character).must_equal :ordinary
    flow.apply(nil)
    _(t.balance).must_equal 40_000
    _(r.balance).must_equal 15_000
  end
end
