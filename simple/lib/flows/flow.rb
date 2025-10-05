# Base Flow: behavioral event with a small contract.
# Subclasses implement tax_character and apply(accounts).
class Flow
  attr_reader :amount

  def initialize(amount:)
    @amount = amount
  end

  def tax_character
    raise NotImplementedError
  end

  # Apply state change to accounts if applicable (e.g., withdrawals, transfers).
  def apply(_accounts)
    raise NotImplementedError
  end
end
