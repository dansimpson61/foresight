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

  it 'serves POST /plan with a valid payload' do
    # First, get the example payload
    get '/plan/example'
    example_payload = last_response.body

    # Now, post it to the /plan endpoint
    post '/plan', example_payload, { 'CONTENT_TYPE' => 'application/json' }
    
    # Check the response
    expect(last_response.status).to eq(200)
    response_data = JSON.parse(last_response.body)
    expect(response_data).to be_a(Hash)
    expect(response_data['data']).to have_key('inputs')
    expect(response_data['data']).to have_key('results')
    expect(response_data['data']['results']).to have_key('do_nothing')
  end
end
