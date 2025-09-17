# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Foresight UI', type: :feature do
  it 'updates the total conversions when the tax bracket ceiling slider is changed' do
    visit '/ui'
    expect(page).to have_content('Foresight')
    conversions_before = find('[data-plan-form-target="totalConversionsValue"]').text
    find('[data-plan-form-target="taxBracketCeilingInput"]').set('150000').trigger('input')
    expect(find('[data-plan-form-target="totalConversionsValue"]')).not_to have_text(conversions_before)
  end
end
