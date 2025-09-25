# frozen_string_literal: true
require_relative 'modules/voluntary'

module Foresight
  # A collection of classes to represent discrete financial events that occur within a year.
  # These events have a taxable impact and can be audited and narrated.
  module FinancialEvent
    # Base class for financial events, capturing common attributes.
    class Base
      attr_reader :year, :taxable_ordinary, :taxable_capital_gains

      def initialize(year:, taxable_ordinary: 0.0, taxable_capital_gains: 0.0)
        @year = year
        @taxable_ordinary = taxable_ordinary
        @taxable_capital_gains = taxable_capital_gains
      end
    end

    # Represents a forced, taxable withdrawal from a traditional account to satisfy IRS rules.
    class RequiredMinimumDistribution < Base
      attr_reader :source_account, :amount

      def initialize(year:, source_account:, amount:)
        super(year: year, taxable_ordinary: amount)
        @source_account = source_account
        @amount = amount
      end
    end

    # Represents a strategic, taxable conversion of pre-tax assets to a Roth account.
    class RothConversion < Base
      include Foresight::Voluntary
      attr_reader :source_account, :destination_account, :amount

      def initialize(year:, source_account:, destination_account:, amount:)
        super(year: year, taxable_ordinary: amount)
        @source_account = source_account
        @destination_account = destination_account
        @amount = amount
      end
    end

    # Represents a withdrawal from any account to cover spending needs.
    class SpendingWithdrawal < Base
      attr_reader :source_account, :amount_withdrawn

      def initialize(year:, source_account:, amount_withdrawn:, taxable_ordinary: 0.0, taxable_capital_gains: 0.0)
        super(year: year, taxable_ordinary: taxable_ordinary, taxable_capital_gains: taxable_capital_gains)
        @source_account = source_account
        @amount_withdrawn = amount_withdrawn
      end
    end
  end
end
