#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'json'
require 'slim'
require_relative './foresight'

set :protection, except: :frame_options
set :logging, true
set :views, File.expand_path('views', __dir__)

helpers do
  def json_params
    request.body.rewind
    raw = request.body.read
    return {} if raw.nil? || raw.strip.empty?
    JSON.parse(raw, symbolize_names: true)
  rescue JSON::ParserError
    halt 400, { error: 'Invalid JSON' }.to_json
  end
end

get '/' do
  content_type :json
  { status: 'ok', service: 'foresight', version: Foresight::PlanService::SCHEMA_VERSION }.to_json
end

get '/strategies' do
  content_type :json
  svc = Foresight::PlanService.new
  { strategies: svc.list_strategies }.to_json
end

post '/plan' do
  content_type :json
  params = json_params
  Foresight::PlanService.run(params)
end

# Friendly helper page and example for GET /plan
get '/plan' do
  content_type :html
  <<~HTML
  <!doctype html>
  <meta charset="utf-8">
  <title>Foresight /plan</title>
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Inter, sans-serif; margin: 2rem; color: #111; }
    textarea { width: 100%; height: 16rem; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.9rem; }
    pre { background: #f7f7f7; padding: 1rem; overflow: auto; }
    .row { display: flex; gap: 1rem; align-items: center; }
    button { padding: 0.5rem 0.9rem; }
  </style>
  <h1>POST /plan</h1>
  <p>This endpoint expects JSON in the body. Paste or edit the example below and click Run.</p>
  <div class="row">
    <button id="load">Load example</button>
    <button id="run">Run plan</button>
  </div>
  <p></p>
  <textarea id="input"></textarea>
  <h2>Result</h2>
  <pre id="out">(result will appear here)</pre>
  <script>
  const input = document.getElementById('input');
  const out = document.getElementById('out');
  document.getElementById('load').onclick = async () => {
    const r = await fetch('/plan/example');
    input.value = JSON.stringify(await r.json(), null, 2);
  };
  document.getElementById('run').onclick = async () => {
    try {
      const body = JSON.parse(input.value);
      const r = await fetch('/plan', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
      const t = await r.text();
      out.textContent = t;
    } catch (e) { out.textContent = 'Invalid JSON in textarea.'; }
  };
  </script>
  HTML
end

# Minimal UI using Slim at /ui (non-intrusive to API)
get '/ui' do
  svc = Foresight::PlanService.new
  @strategies = svc.list_strategies
  slim :ui
end

get '/plan/example' do
  content_type :json
  example = {
    members: [
      { name: 'Alice', date_of_birth: '1961-06-15' },
      { name: 'Bob',   date_of_birth: '1967-02-10' }
    ],
    accounts: [
      { type: 'TraditionalIRA', owner: 'Alice', balance: 100_000.0 },
      { type: 'RothIRA', owner: 'Alice', balance: 50_000.0 },
      { type: 'TaxableBrokerage', owners: ['Alice','Bob'], balance: 20_000.0, cost_basis_fraction: 0.7 }
    ],
    income_sources: [
      { type: 'SocialSecurityBenefit', recipient: 'Alice', start_year: 2025, pia_annual: 24_000.0, cola_rate: 0.0 },
      { type: 'SocialSecurityBenefit', recipient: 'Bob',   start_year: 2030, pia_annual: 24_000.0, cola_rate: 0.0 }
    ],
    target_spending_after_tax: 60_000.0,
    desired_tax_bracket_ceiling: 94_300.0,
    start_year: 2025,
    years: 5,
    inflation_rate: 0.02,
    growth_assumptions: { traditional_ira: 0.02, roth_ira: 0.03, taxable: 0.01 },
    strategies: [ { key: 'none' }, { key: 'bracket_fill', params: { cushion_ratio: 0.05 } } ]
  }
  JSON.pretty_generate(example)
end
