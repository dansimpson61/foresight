# frozen_string_literal: true

module Foresight
  class Account
    attr_reader :owner

    def initialize(owner:)
      @owner = owner
    end
  end

  class TraditionalIRA < Account
    attr_reader :balance

    def initialize(owner:, balance: 0.0)
      super(owner: owner)
      @balance = balance
    end

    def withdraw(amount)
      amt = [amount, @balance].min
      @balance -= amt
      { cash: amt, taxable_ordinary: amt }
    end

    def convert_to_roth(amount)
      amt = [amount, @balance].min
      @balance -= amt
      { converted: amt, taxable_ordinary: amt }
    end

    def calculate_rmd(age)
      return 0.0 unless age >= owner.rmd_start_age
      divisor = RMD_TABLE.fetch(age, RMD_TABLE.values.last)
      @balance / divisor
    end

    RMD_TABLE = {
      73 => 26.5, 74 => 25.5, 75 => 24.6, 76 => 23.7, 77 => 22.9,
      78 => 22.0, 79 => 21.1, 80 => 20.2, 81 => 19.4, 82 => 18.5,
      83 => 17.7, 84 => 16.8, 85 => 16.0, 86 => 15.2, 87 => 14.4,
      88 => 13.7, 89 => 12.9, 90 => 12.2
    }.freeze

    def grow(rate)
      @balance *= (1 + rate)
    end
  end

  class RothIRA < Account
    attr_reader :balance

    def initialize(owner:, balance: 0.0)
      super(owner: owner)
      @balance = balance
    end

    def withdraw(amount)
      amt = [amount, @balance].min
      @balance -= amt
      { cash: amt, taxable_ordinary: 0.0 }
    end

    def deposit(amount)
      @balance += amount
    end

    def grow(rate)
      @balance *= (1 + rate)
    end
  end

  class TaxableBrokerage < Account
    attr_reader :owners, :balance, :cost_basis_fraction

    MIN_COST_BASIS_FRACTION = 0.1

    def initialize(owners:, balance: 0.0, cost_basis_fraction: 0.7)
      @owners = owners
      @balance = balance
      @cost_basis_fraction = [[cost_basis_fraction.to_f, 1.0].min, MIN_COST_BASIS_FRACTION].max
    end

    def withdraw(amount)
      amt = [amount, @balance].min
      @balance -= amt
      gains_portion = amt * (1 - cost_basis_fraction)
      { cash: amt, taxable_capital_gains: gains_portion }
    end

    def grow(rate)
      @balance *= (1 + rate)
    end
  end
end
