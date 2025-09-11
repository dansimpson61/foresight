# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'

module Foresight
  # Minimal Money wrapper for future precision improvements.
  # Not yet integrated; present as a refinement path.
  class Money
    attr_reader :amount

    def initialize(amount)
      @amount = to_bd(amount)
    end

    def +(other) = Money.new(@amount + to_bd(extract(other)))
    def -(other) = Money.new(@amount - to_bd(extract(other)))
    def *(num)   = Money.new(@amount * to_bd(num))
    def /(num)   = Money.new(@amount / to_bd(num))

    def to_f = @amount.to_f
    def to_s = format('%.2f', to_f)

    private

    def to_bd(v)
      return v.amount if v.is_a?(Money)
      case v
      when BigDecimal then v
      when Integer then BigDecimal(v, 0)
      when Float then BigDecimal(v.to_s)
      when String then BigDecimal(v)
      else BigDecimal(v.to_f.to_s)
      end
    end

    def extract(v)
      v.is_a?(Money) ? v.amount : v
    end
  end
end
