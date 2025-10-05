require 'minitest/autorun'
require 'minitest/spec'
require_relative '../../lib/policies/tax_policy'

describe TaxPolicy do
  let(:brackets) do
    {
      mfj: {
        ordinary: [
          { income: 190750, rate: 0.24 },
          { income: 89450, rate: 0.22 },
          { income: 22000, rate: 0.12 },
          { income: 0, rate: 0.10 }
        ],
        capital_gains: [
          { income: 89450, rate: 0.0 },
          { income: 583750, rate: 0.20 }
        ],
        social_security_provisional_income: { phase1_start: 32000, phase2_start: 44000 }
      },
      standard_deduction: { mfj: 29200 }
    }
  end

  it 'computes ordinary and CG taxes with deduction' do
    taxes = TaxPolicy.calculate_taxes(100_000, 10_000, brackets)
    _(taxes).must_be_kind_of Hash
    _(taxes[:total]).must_be :>=, 0
  end

  it 'caps taxable SS at 85% of total' do
    taxable = TaxPolicy.taxable_social_security(200_000, 30_000, brackets)
    _(taxable).must_be_close_to 25_500, 0.01
  end

  it 'zeroes taxable SS below thresholds' do
    taxable = TaxPolicy.taxable_social_security(0, 10_000, brackets)
    _(taxable).must_equal 0
  end
end
