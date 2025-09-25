#!/usr/bin/env ruby
# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/conversion_strategies'
require_relative '../../models/household'
require_relative '../../models/person'
require_relative '../../models/accounts'
require_relative '../../models/tax_year'
require_relative '../../models/tax_brackets'

RSpec.describe Foresight::ConversionStrategies do
  let(:p1) { Foresight::Person.new(name: 'Person 1', date_of_birth: '1960-01-01') }
  let(:p2) { Foresight::Person.new(name: 'Person 2', date_of_birth: '1962-01-01') }
  let(:base_accounts) do
    [
      Foresight::TraditionalIRA.new(owner: p1, balance: 200_000),
      Foresight::RothIRA.new(owner: p1, balance: 50_000)
    ]
  end
  let(:household) do
    Foresight::Household.new(
      members: [p1, p2],
      filing_status: 'married_filing_jointly',
      state: 'CA',
      accounts: base_accounts,
      income_sources: [],
      annual_expenses: 60_000,
      emergency_fund_floor: 25_000,
      withdrawal_hierarchy: [:cash, :taxable, :traditional, :roth]
    )
  end
  
  # Stub the data loading to make tests self-contained and fast.
  before do
    allow(Foresight::TaxBrackets).to receive(:for_year).with(anything).and_return({
      'standard_deduction' => {
        'married_filing_jointly' => 29200
      },
      'married_filing_jointly' => {
        'ordinary' => [
          { 'rate' => 0.10, 'income' => 0 },
          { 'rate' => 0.12, 'income' => 23200 },
          { 'rate' => 0.22, 'income' => 94300 },
          { 'rate' => 0.24, 'income' => 201050 }
        ],
        'social_security_provisional_income' => {
            'phase1_start' => 32000,
            'phase2_start' => 44000
        }
      }
    })
  end

  let(:tax_year) { Foresight::TaxYear.new(year: 2024) }
  let(:standard_deduction) { tax_year.standard_deduction('married_filing_jointly') }
  let(:args) do
    {
      household: household,
      tax_year: tax_year,
      base_taxable_income: 10_000,
      spending_need: 0,
      provisional_income_before_strategy: 10_000,
      standard_deduction: standard_deduction
    }
  end
end
