# frozen_string_literal: true

require 'spec_helper'
require_relative '../../models/person'

RSpec.describe Foresight::Person do
  describe 'age calculation and RMD eligibility' do
    # SECURE 2.0 Act: RMD age is 73 for those born between 1951 and 1959
    context 'for a person born in 1955' do
      let(:person) { Foresight::Person.new(name: 'Test Person', date_of_birth: '1955-07-01') }

      it 'correctly calculates age' do
        expect(person.age_in(2023)).to eq(68)
        expect(person.age_in(2028)).to eq(73)
      end

      it 'has an RMD start age of 73' do
        expect(person.rmd_start_age).to eq(73)
      end

      it 'is not RMD eligible before age 73' do
        expect(person.rmd_eligible_in?(2027)).to be(false) # Age 72
      end

      it 'is RMD eligible at age 73' do
        expect(person.rmd_eligible_in?(2028)).to be(true) # Age 73
      end
    end

    # SECURE 2.0 Act: RMD age is 75 for those born in 1960 or later
    context 'for a person born in 1961' do
      let(:person) { Foresight::Person.new(name: 'Younger Person', date_of_birth: '1961-03-15') }

      it 'correctly calculates age' do
        expect(person.age_in(2023)).to eq(62)
      end

      it 'has an RMD start age of 75' do
        expect(person.rmd_start_age).to eq(75)
      end

      it 'is not RMD eligible before age 75' do
        expect(person.rmd_eligible_in?(2035)).to be(false) # Age 74
      end

      it 'is RMD eligible at age 75' do
        expect(person.rmd_eligible_in?(2036)).to be(true) # Age 75
      end
    end
  end
end
