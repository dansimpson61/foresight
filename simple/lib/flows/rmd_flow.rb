require_relative '../traditional_ira'
require_relative './flow'

# RMDFlow - forced withdrawal from Traditional IRA; ordinary income.
class RMDFlow < Flow
  attr_reader :account

  def initialize(amount:, account:)
    super(amount: amount)
    @account = account
  end

  def tax_character
    :ordinary
  end

  def apply(_accounts)
    # Reduce the specific Traditional IRA by RMD amount (already validated upstream)
    @account.withdraw(@amount)
  end
end
