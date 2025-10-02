require_relative 'asset'

class TraditionalIRA < Asset
  def initialize(balance:, owner:)
    super(balance: balance, owner: owner, taxability: :tax_deferred)
  end

  def tax_on_withdrawal(amount)
    { ordinary_income: amount, capital_gains: 0 }
  end

  def rmd_required?(age)
    age >= 73
  end

  def calculate_rmd(age)
    return 0 unless rmd_required?(age)
    # IRS Uniform Lifetime Table divisors
    rmd_divisor = {
      73 => 26.5, 74 => 25.5, 75 => 24.6, 76 => 23.7, 77 => 22.9,
      78 => 22.0, 79 => 21.2, 80 => 20.3, 81 => 19.5, 82 => 18.7,
      83 => 17.9, 84 => 17.1, 85 => 16.3, 86 => 15.5, 87 => 14.8,
      88 => 14.1, 89 => 13.4, 90 => 12.7, 91 => 12.0, 92 => 11.4,
      93 => 10.8, 94 => 10.2, 95 => 9.6, 96 => 9.1,
      97 => 8.6, 98 => 8.1, 99 => 7.6, 100 => 7.1
    }
    divisor = rmd_divisor[age] || 7.1 # Fallback for older ages
    (@balance / divisor).round(2)
  end
end