require 'minitest/autorun'
require_relative '../../lib/flows/social_security_flow'

class SocialSecurityFlowSpec < Minitest::Test
  def test_tax_character
    flow = SocialSecurityFlow.new(amount: 12000, recipient: 'Pat')
    assert_equal :social_security, flow.tax_character
  end

  def test_apply_is_noop
    flow = SocialSecurityFlow.new(amount: 12000, recipient: 'Pat')
    assert_nil flow.apply(nil)
  end
end
