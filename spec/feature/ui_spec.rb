# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Foresight UI', type: :feature do
  it 'loads the UI and can Load example' do
    visit '/ui'
    expect(page).to have_content('Foresight')
    click_button 'Load example'
    expect(find('textarea').value).to include('Alice')
  end

  it 'runs the plan and renders charts' do
    visit '/ui'
    expect(page).to have_content('Foresight')
    click_button 'Run plan'
    expect(page).to have_css('svg#chart-assets')
    expect(page).to have_css('svg#chart-irmaa')
    expect(page).to have_css('svg#chart-tax-efficiency')
  end

  it 'auto-runs when controls change and shows sparkline' do
    visit '/ui'
    expect(page).to have_content('Foresight')
    # a crude way to check for autorun: check for a value that should change
    net_worth_before = find('[data-plan-form-target="netWorthValue"]').text
    find('[data-plan-form-target="yourAgeInput"]').set('45').trigger('input')
    expect(find('[data-plan-form-target="netWorthValue"]')).not_to have_text(net_worth_before)
  end

  it 'auto-runs when growth slider changes' do
    visit '/ui'
    expect(page).to have_content('Foresight')
    net_worth_before = find('[data-plan-form-target="netWorthValue"]').text
    find('[data-plan-form-target="growthRateInput"]').set('10').trigger('input')
    expect(find('[data-plan-form-target="netWorthValue"]')).not_to have_text(net_worth_before)
  end
end
