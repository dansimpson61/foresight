# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'App endpoints', type: :request do
  # Fetches the canonical example payload and returns just the inner :payload hash,
  # ensuring our tests always use a perfectly-structured, valid set of parameters.
  def get_canonical_payload
    get '/plan/example'
    expect(last_response.status).to eq(200)
    JSON.parse(last_response.body, symbolize_names: true)[:payload]
  end

  it 'serves /ui' do
    get '/ui'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to include('Foresight')
  end

  it 'serves /plan/example' do
    get '/plan/example'
    expect(last_response.status).to eq(200)
    response_data = JSON.parse(last_response.body, symbolize_names: true)
    expect(response_data).to be_a(Hash)
    expect(response_data).to have_key(:payload)
  end

  it 'serves POST /plan with a valid payload' do
    valid_payload = get_canonical_payload
    wrapped_payload = { payload: valid_payload }
    
    post '/plan', wrapped_payload.to_json, { 'CONTENT_TYPE' => 'application/json' }
    
    expect(last_response.status).to eq(200)
    response_data = JSON.parse(last_response.body, symbolize_names: true)
    
    expect(response_data).to have_key(:payload)
    expect(response_data[:payload]).to have_key(:data)
    expect(response_data[:payload][:data]).to have_key(:inputs)
    expect(response_data[:payload][:data]).to have_key(:results)
    expect(response_data[:payload][:data][:results]).to have_key(:do_nothing)
  end

  it 'returns a 400 Bad Request for a payload with missing keys' do
    invalid_payload = get_canonical_payload
    invalid_payload.delete(:annual_expenses) # Corrupt the payload
    
    wrapped_payload = { payload: invalid_payload }
    post '/plan', wrapped_payload.to_json, { 'CONTENT_TYPE' => 'application/json' }
    
    expect(last_response.status).to eq(400)
    error_data = JSON.parse(last_response.body, symbolize_names: true)
    
    expect(error_data[:payload][:status]).to eq('error')
    expect(error_data[:payload][:communication_step]).to eq('Request (Frontend -> Backend)')
    
    # Check for the presence of the key fields in the error details,
    # rather than an exact match of the error message.
    details = error_data[:payload][:details]
    expect(details).to be_an(Array)
    missing_keys_error = details.find { |e| e[:field] == 'annual_expenses' && e[:issue] == 'missing' }
    expect(missing_keys_error).not_to be_nil
  end
end
