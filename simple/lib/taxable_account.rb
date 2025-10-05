require_relative 'asset'

# TaxableAccount - taxable; withdrawals realize capital gains based on cost basis fraction.
class TaxableAccount < Asset
  attr_reader :cost_basis_fraction

  def initialize(balance:, owner:, cost_basis_fraction: 0.7)
    super(balance: balance, owner: owner, taxability: :taxable)
    @cost_basis_fraction = cost_basis_fraction
  end

  def tax_on_withdrawal(amount)
    gains = amount * (1 - @cost_basis_fraction)
    { ordinary_income: 0, capital_gains: gains }
  end

  def generate_dividends(yield_rate)
    @balance * yield_rate
  end
end