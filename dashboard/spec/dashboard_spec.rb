require_relative 'spec_helper'

RSpec.describe "Dashboard App", type: :feature do
  it "loads the main page" do
    visit "/"
    expect(page.status_code).to eq(200)
    expect(page).to have_content("Test Dashboard")
  end
end
