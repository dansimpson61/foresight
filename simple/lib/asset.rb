# ============================================================================
# ASSETS - Things you own that have value.
# Minimal contract: state (balance, owner, taxability) + grow/withdraw/deposit,
# and a tax_on_withdrawal(amount) method implemented by subclasses.
# ============================================================================

class Asset
  attr_reader :balance, :owner, :taxability

  def initialize(balance:, owner:, taxability:)
    @balance = balance
    @owner = owner
    @taxability = taxability
  end

  # Every asset can grow
  def grow(rate)
    @balance *= (1 + rate)
  end

  # Every asset can be withdrawn from
  def withdraw(amount)
    actual = [amount, @balance].min
    @balance -= actual
    actual
  end

  def deposit(amount)
    @balance += amount
  end

  # Tax treatment varies by asset type
  def tax_on_withdrawal(amount)
    raise NotImplementedError
  end
end