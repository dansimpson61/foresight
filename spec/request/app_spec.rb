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

  it 'returns a 400 Bad Request for a payload with missing keys' do
    # Get the example payload and corrupt it by removing a required key
    get '/plan/example'
    payload_hash = JSON.parse(last_response.body, symbolize_names: true)
    payload_hash.delete(:annual_expenses)
    
    # Now, post the invalid payload to the /plan endpoint
    post '/plan', payload_hash.to_json, { 'CONTENT_TYPE' => 'application/json' }
    
    # Check the response for the expected error
    expect(last_response.status).to eq(400)
    error_data = JSON.parse(last_response.body, symbolize_names: true)
    
    expect(error_data[:status]).to eq('error')
    expect(error_data[:communication_step]).to eq('Request (Frontend -> Backend)')
    
    # Corrected: The errors array is directly under the :details key
    missing_keys_error = error_data[:details].find { |e| e[:field] == 'annual_expenses' && e[:issue] == 'missing' }
    expect(missing_keys_error).not_to be_nil
  end
end
