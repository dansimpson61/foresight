# frozen_string_literal: true
require 'spec_helper'
require 'timeout'

RSpec.describe 'Foresight UI', type: :feature, js: true do
  # Wait until the given JS expression returns a truthy value or timeout
  def wait_for_js(expr, timeout: 10)
    Timeout.timeout(timeout) do
      loop do
        val = page.evaluate_script(expr)
        return val if val
        sleep 0.05
      end
    end
  end

  it 'loads the UI and can Load example' do
    visit '/ui'
    expect(page).to have_content('Foresight')

    # Click the Load example button
    expect(page).to have_selector('#btn-load-example')
    click_button('Load example')

  # Wait for deterministic UI state OR textarea populated with example keys
  wait_for_js('(() => { const s=document.getElementById("ui-state"); if(s && s.dataset.state==="example-loaded") return true; const v=document.getElementById("input")?.value||""; return v.includes("members"); })()', timeout: 10)
  end

  it 'runs the plan and renders charts' do
    visit '/ui'
    # Load example first and wait for explicit state
    click_button('Load example')
    wait_for_js('document.getElementById("ui-state")?.dataset.state === "example-loaded"', timeout: 10)

    # Run plan
    click_button('Run plan')

  # Expect key result elements to exist (allow time for fetch/render)
  wait_for_js('(() => { const s=document.getElementById("ui-state"); if(s && s.dataset.state==="plan-ready") return true; return document.querySelectorAll("#results-table tbody tr").length>0; })()', timeout: 15)
  expect(page).to have_selector('#chart-assets', wait: 5)
  expect(page).to have_selector('#timeline-irmaa', wait: 5)
  expect(page).to have_selector('#eff-gauge', wait: 5)
    wait_for_js('document.querySelectorAll("#results-table tbody tr").length > 0', timeout: 10)
  end

  it 'auto-runs when controls change and shows sparkline' do
    visit '/ui'
    # Load example first
    click_button('Load example')
    wait_for_js('document.getElementById("ui-state")?.dataset.state === "example-loaded"', timeout: 10)

    # Change a control (bracket ceiling) to trigger debounced auto-run
    # Ensure an actual 'input' event fires for Stimulus by dispatching it explicitly
    page.execute_script("(() => { const el = document.getElementById('bracket'); el.value='10000'; el.dispatchEvent(new Event('input', { bubbles: true })); })()")

    # Wait for plan-ready or visible results (debounce + fetch)
    wait_for_js('(() => { const s=document.getElementById("ui-state"); if(s && s.dataset.state==="plan-ready") return true; if(document.querySelectorAll("#results-table tbody tr").length>0) return true; return false; })()', timeout: 15)

    # Sparkline should be present and have an SVG child
    expect(page).to have_selector('.sparkline svg', wait: 5)
  end
end
