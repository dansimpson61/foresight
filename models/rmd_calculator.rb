# frozen_string_literal: true

module Foresight
  # Calculates Required Minimum Distributions (RMDs) from retirement accounts.
  class RmdCalculator
    # The Uniform Lifetime Table for RMD calculations.
    # Source: IRS Publication 590-B, Appendix B
    UNIFORM_LIFETIME_TABLE = {
      72 => 27.4, 73 => 26.5, 74 => 25.5, 75 => 24.6, 76 => 23.7,
      77 => 22.9, 78 => 22.0, 79 => 21.1, 80 => 20.2, 81 => 19.4,
      82 => 18.5, 83 => 17.7, 84 => 16.8, 85 => 16.0, 86 => 15.2,
      87 => 14.4, 88 => 13.7, 89 => 12.9, 90 => 12.2, 91 => 11.5,
      92 => 10.8, 93 => 10.1, 94 => 9.5,  95 => 8.9,  96 => 8.4,
      97 => 7.8,  98 => 7.3,  99 => 6.8,  100 => 6.4, 101 => 6.0,
      102 => 5.6, 103 => 5.2, 104 => 4.9, 105 => 4.6, 106 => 4.3,
      107 => 4.1, 108 => 3.9, 109 => 3.7, 110 => 3.5, 111 => 3.4,
      112 => 3.3, 113 => 3.1, 114 => 3.0, 115 => 2.9, 116 => 2.8,
      117 => 2.7, 118 => 2.5, 119 => 2.3, 120 => 2.0
    }.freeze

    def self.calculate(age:, balance:)
      # RMDs were updated to age 73 by the SECURE 2.0 act, but we use 72
      # to be conservative and handle anyone who turned 72 before 2023.
      # A more precise implementation would check the birth year.
      return 0.0 if age < 72

      divisor = UNIFORM_LIFETIME_TABLE[age]
      return 0.0 unless divisor # Age might be over 120

      (balance / divisor).round(2)
    end
  end
end
