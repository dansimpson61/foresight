require_relative 'spec_helper'

RSpec.describe "Dashboard App", type: :feature do
  it "loads the main page" do
    visit "/"
    expect(page).to have_http_status(:ok)
    expect(page).to have_content("Test Dashboard")
  end
end
