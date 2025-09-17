# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'App endpoints', type: :request do
  it 'serves /ui' do
    get '/ui'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include('Foresight')
  end

  it 'serves /plan/example' do
    get '/plan/example'
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to be_a(Hash)
  end
end
