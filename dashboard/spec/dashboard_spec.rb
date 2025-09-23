require_relative 'spec_helper'

RSpec.describe "Dashboard App", type: :request do
  it "loads the main page" do
    get "/"
    expect(last_response).to be_ok
    expect(last_response.body).to include("Test Dashboard")
  end
end
