require_relative './flow'

# SocialSecurityFlow - income-only flow; tax handled by TaxPolicy via taxable portion logic.
class SocialSecurityFlow < Flow
  attr_reader :recipient

  def initialize(amount:, recipient:)
    super(amount: amount)
    @recipient = recipient
  end

  def tax_character
    :social_security
  end

  def apply(_accounts)
    # No account mutation; income recognized at household level.
    # We still treat flows as ledger entries for observability.
    nil
  end
end
