# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/person'
require_relative '../../models/income_sources'

RSpec.describe Foresight::IncomeSource do
  let(:recipient) { Foresight::Person.new(name: 'Test Recipient', date_of_birth: '1960-01-01') } # Born in 1960, FRA is 67

  describe 'Salary' do
    it 'reports its gross amount' do
      salary = Foresight::Salary.new(recipient: recipient, annual_gross: 80_000)
      expect(salary.annual_gross).to eq(80_000)
    end
  end

  describe 'Pension' do
    it 'calculates state-specific taxability' do
      pension = Foresight::Pension.new(recipient: recipient, annual_gross: 50_000)
      # NY has a $20k exclusion for those 59.5 or older
      expect(pension.taxable_amount(state: 'NY', recipient_age: 60)).to eq(30_000)
      expect(pension.taxable_amount(state: 'NY', recipient_age: 55)).to eq(50_000)
      expect(pension.taxable_amount(state: 'CA', recipient_age: 65)).to eq(50_000)
    end
  end

  describe 'Social Security Benefit' do
    let(:pia) { 30_000 } # Primary Insurance Amount

    context 'when claiming at Full Retirement Age (67)' do
      it 'provides the full PIA' do
        benefit = Foresight::SocialSecurityBenefit.new(recipient: recipient, pia_annual: pia, claiming_age: 67)
        allow(recipient).to receive(:age_in).and_return(67)
        expect(benefit.annual_benefit_for(2027)).to be_within(0.01).of(pia)
      end
    end

    context 'when claiming early at age 62' do
      it 'provides a reduced benefit' do
        benefit = Foresight::SocialSecurityBenefit.new(recipient: recipient, pia_annual: pia, claiming_age: 62)
        allow(recipient).to receive(:age_in).and_return(62)
        # Reduction for 60 months early is 30%
        expect(benefit.annual_benefit_for(2022)).to be_within(0.01).of(pia * 0.70)
      end
    end

    context 'when claiming late at age 70' do
      it 'provides an increased benefit' do
        benefit = Foresight::SocialSecurityBenefit.new(recipient: recipient, pia_annual: pia, claiming_age: 70)
        allow(recipient).to receive(:age_in).and_return(70)
        # Credit for 36 months late is 24%
        expect(benefit.annual_benefit_for(2030)).to be_within(0.01).of(pia * 1.24)
      end
    end

    it 'provides no benefit before claiming age' do
      benefit = Foresight::SocialSecurityBenefit.new(recipient: recipient, pia_annual: pia, claiming_age: 70)
      allow(recipient).to receive(:age_in).and_return(69)
      expect(benefit.annual_benefit_for(2029)).to eq(0)
    end
  end
end
