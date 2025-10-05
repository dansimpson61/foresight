require_relative 'asset'

# RothIRA - tax-free growth; withdrawals assumed tax-free in this simplified model; no RMDs.
class RothIRA < Asset
  def initialize(balance:, owner:)
    super(balance: balance, owner: owner, taxability: :tax_free)
  end

  def tax_on_withdrawal(amount)
    { ordinary_income: 0, capital_gains: 0 }
  end

  def rmd_required?(age)
    false  # No RMDs on Roth!
  end
end