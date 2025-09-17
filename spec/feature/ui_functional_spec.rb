# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Foresight UI', type: :feature do
  it 'loads the UI, populates initial results, and updates them on input change' do
    visit '/ui'
    expect(page).to have_content('Foresight')
    expect(page).to have_css('#chart-assets')
    expect(page).to have_css('#chart-irmaa')
    expect(page).to have_css('#chart-tax-efficiency')
    expect(find('[data-plan-form-target="lifetimeTaxesValue"]')).to have_text('$')

    # a crude way to check for autorun: check for a value that should change
    net_worth_before = find('[data-plan-form-target="netWorthValue"]').text
    find('[data-plan-form-target="yourAgeInput"]').set('45').trigger('input')
    expect(find('[data-plan-form-target="netWorthValue"]')).not_to have_text(net_worth_before)
  end
end
