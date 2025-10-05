require 'minitest/autorun'
require 'minitest/spec'
require_relative '../../lib/traditional_ira'
require_relative '../../lib/flows/rmd_flow'

describe RMDFlow do
  it 'reduces the traditional IRA and is ordinary income' do
    ira = TraditionalIRA.new(balance: 100_000, owner: 'Pat')
    flow = RMDFlow.new(amount: 10_000, account: ira)
    _(flow.tax_character).must_equal :ordinary
    flow.apply(nil)
    _(ira.balance).must_equal 90_000
  end
end
