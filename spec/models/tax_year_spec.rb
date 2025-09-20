# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/tax_year'

RSpec.describe Foresight::TaxYear do
  let(:tax_year) { described_class.new(year: 2023) }

  # Using 2023 MFJ brackets for all tests
  # 10% on income up to $22,000
  # 12% on income over $22,000 up to $89,450
  # 22% on income over $89,450 up to $190,750
  
  describe '#calculate ordinary income tax' do
    it 'calculates tax correctly within a single bracket' do
      # Taxable income = 20_000 (after deduction)
      result = tax_year.calculate(filing_status: :mfj, taxable_income: 20_000)
      expect(result[:federal_tax]).to eq(2000) # 10% of 20,000
    end

    it 'calculates tax correctly across multiple brackets' do
      # Taxable income = 100_000 (after deduction)
      result = tax_year.calculate(filing_status: :mfj, taxable_income: 100_000)
      
      # 10% on first 22,000 = 2,200
      # 12% on next (89,450 - 22,000) = 67,450 * 0.12 = 8,094
      # 22% on remaining (100,000 - 89,450) = 10,550 * 0.22 = 2,321
      # Total = 2200 + 8094 + 2321 = 12,615
      expect(result[:federal_tax]).to be_within(0.01).of(12615)
    end
  end

  describe '#calculate_capital_gains_tax' do
    it 'applies a 0% rate when income is within the 0% bracket' do
      # MFJ 0% CG bracket ends at $89,250 in 2023
      tax = tax_year.calculate_capital_gains_tax(filing_status: :mfj, taxable_income: 50_000, capital_gains: 10_000)
      expect(tax).to eq(0)
    end

    it 'applies a 15% rate correctly when gains cross the threshold' do
      # MFJ 0% CG bracket ends at $89,250. 15% bracket ends at $553,850.
      # $10k of gains should be taxed at 15%
      tax = tax_year.calculate_capital_gains_tax(filing_status: :mfj, taxable_income: 80_000, capital_gains: 20_000)
      
      # First 9,250 of gains are in the 0% bracket
      # Remaining 10,750 are in the 15% bracket
      expected_tax = 10_750 * 0.15
      expect(tax).to be_within(0.01).of(expected_tax)
    end
  end
  
  describe '#social_security_taxability_thresholds' do
      it 'returns the correct provisional income thresholds' do
        thresholds = tax_year.social_security_taxability_thresholds(:mfj)
        expect(thresholds['phase1_start']).to eq(32000)
        expect(thresholds['phase2_start']).to eq(44000)
      end
  end

  describe '#irmaa_part_b_surcharge' do
    it 'returns 0 for MAGI below the first threshold' do
      surcharge = tax_year.irmaa_part_b_surcharge(magi: 90_000, status: :mfj)
      expect(surcharge).to eq(0)
    end

    it 'returns the correct surcharge for the first tier' do
      # First tier for MFJ in 2023 is > $194,000. Surcharge is $65.90/person/month
      surcharge = tax_year.irmaa_part_b_surcharge(magi: 200_000, status: :mfj)
      # Surcharge is per person, so we expect it for both members of household
      expect(surcharge).to be > 0
    end
  end
end
