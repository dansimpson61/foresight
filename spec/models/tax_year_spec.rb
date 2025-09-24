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

  context 'when handling multiple years' do
    let(:tax_year_2023) { described_class.new(year: 2023) }
    let(:tax_year_2024) { described_class.new(year: 2024) }

    it 'loads the correct standard deduction for different years' do
      deduction_2023 = tax_year_2023.standard_deduction(:single)
      deduction_2024 = tax_year_2024.standard_deduction(:single)

      expect(deduction_2023).to eq(13850)
      expect(deduction_2024).to eq(14600)
      expect(deduction_2023).not_to eq(deduction_2024)
    end

    it 'calculates taxes using the correct brackets for different years' do
      # A taxable income of $50,000 for a single filer
      # 2023 brackets: 10% on first 11k, 12% on next (44725-11k), 22% on remainder
      # 2024 brackets: 10% on first 11.6k, 12% on next (47150-11.6k), 22% on remainder

      tax_2023 = tax_year_2023.calculate(filing_status: :single, taxable_income: 50_000)[:federal_tax]
      tax_2024 = tax_year_2024.calculate(filing_status: :single, taxable_income: 50_000)[:federal_tax]

      # 2023 calc: (11000*0.1) + ((44725-11000)*0.12) + ((50000-44725)*0.22) = 1100 + 4047 + 1160.5 = 6307.5
      # 2024 calc: (11600*0.1) + ((47150-11600)*0.12) + ((50000-47150)*0.22) = 1160 + 4266 + 627 = 6053

      expect(tax_2023).to be_within(0.01).of(6307.5)
      expect(tax_2024).to be_within(0.01).of(6053)
      expect(tax_2023).not_to eq(tax_2024)
    end
  end
end
