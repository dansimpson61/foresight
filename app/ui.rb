# frozen_string_literal: true

require 'sinatra/base'
require 'slim'
require_relative '../foresight'

module Foresight
  class UI < Sinatra::Base
    set :views, File.expand_path('../../views', __FILE__)

    get '/' do
      slim :home
    end

    get '/ui' do
      svc = Foresight::PlanService.new
      @strategies = svc.list_strategies
      slim :ui
    end

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
  end
end
