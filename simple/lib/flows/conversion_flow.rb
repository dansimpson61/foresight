require_relative '../traditional_ira'
require_relative '../roth_ira'
require_relative './flow'

# ConversionFlow - transfers from Traditional IRA to Roth IRA; ordinary income on converted amount.
class ConversionFlow < Flow
  attr_reader :from_account, :to_account

  def initialize(amount:, from_account:, to_account:)
    super(amount: amount)
    @from_account = from_account
    @to_account = to_account
  end

  def tax_character
    :ordinary
  end

  def apply(_accounts)
    pulled = @from_account.withdraw(@amount)
    @to_account.deposit(pulled)
  end
end
