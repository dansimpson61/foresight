# frozen_string_literal: true

require 'spec_helper'
require 'capybara/rspec'

RSpec.describe 'Capybara Smoke Test', type: :feature do
  it 'loads the main page and finds the main heading' do
    visit '/ui'
    expect(page).to have_content('Foresight')
    expect(page).to have_css('h1', text: 'Foresight')
  end
end
