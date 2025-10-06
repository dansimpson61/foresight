require 'bundler/setup'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'minitest/spec'
require_relative '../app'
require 'rack/mock'

class ViewsSpec < Minitest::Test
  def setup
    @app = Foresight::Simple::UI.new
    @req = Rack::MockRequest.new(@app)
  end

  def test_root_renders_and_includes_key_assets_and_badge
    res = @req.get('/')
    assert_equal 200, res.status

    body = res.body
    # Stylesheet and JS controllers should be referenced
    assert_includes body, '/css/app.css'
    assert_includes body, '/js/application.js'
    assert_includes body, '/js/chart_controller.js'

    # Embedded data scripts should exist
    assert_includes body, 'id="simulation-data"'
    assert_includes body, 'id="default-profile-data"'

    # Badge should be present and show default mode
    assert_includes body, 'Visualization'
    assert_includes body, 'data-viz-target="badge"'
    assert_includes body, 'fill_to_bracket'

    # JSON should include both scenarios
    assert_includes body, '"do_nothing"'
    assert_includes body, '"fill_bracket"'

    # A couple of expected headings should be present
    assert_includes body, 'Your Financial Profile'
    assert_includes body, 'Annual Income & Tax Details'

    # Profile editor contains key household fields
    assert_includes body, 'State (2-letter)'
    assert_includes body, 'Emergency Fund Floor'
    assert_includes body, 'Withdrawal Hierarchy'

    # Simulation editor contains key knobs
    assert_includes body, 'Simulation Parameters'
    assert_includes body, 'Target Tax Bracket Ceiling'
  end
end
