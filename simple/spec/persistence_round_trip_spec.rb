ENV['FORESIGHT_ENV'] = 'test'
require 'bundler/setup'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'minitest/spec'
require_relative '../app'
require 'rack/mock'

class PersistenceRoundTripSpec < Minitest::Test
  def setup
    @app = Foresight::Simple::UI.new
    @req = Rack::MockRequest.new(@app)
  end

  def test_save_defaults_then_get_reflects_global_defaults
    body = {
      profile: {
        start_year: 2026,
        years_to_simulate: 7,
        inflation_rate: 0.02,
        growth_assumptions: { traditional: 0.04, roth: 0.05, taxable: 0.03, cash: 0.01 },
        household: { filing_status: 'mfj', state: 'CA', annual_expenses: 222333, emergency_fund_floor: 40000, withdrawal_hierarchy: [:taxable, :traditional, :roth] },
        members: [ { name: 'Pat', date_of_birth: '1964-05-01' } ],
        accounts: [ { type: :traditional, owner: 'Pat', balance: 100000 } ],
        income_sources: []
      },
      strategy: 'fill_to_bracket',
      strategy_params: { ceiling: 77777 }
    }.to_json

    post = @req.post('/save_defaults', { 'CONTENT_TYPE' => 'application/json', input: body })
    assert_equal 200, post.status

    # Now GET and ensure the page includes our saved default values
    res = @req.get('/')
    assert_equal 200, res.status
    html = res.body
    assert_includes html, '222333'
    assert_includes html, '77777'
    # Cleanup: clear defaults to avoid polluting future runs
    @req.post('/clear_defaults')
  end
end
