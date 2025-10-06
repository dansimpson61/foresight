require 'minitest/autorun'
require_relative '../../lib/decisions/claim_ss_decision'

class ClaimSSDecisionSpec < Minitest::Test
  Decisions = Foresight::Simple::Decisions

  def test_no_flow_before_claiming_age
    ages = { 'Pat' => 65 }
    sources = [{ type: :social_security, recipient: 'Pat', pia_annual: 30000, claiming_age: 67 }]

    flows = Decisions::ClaimSSDecision.decide_for_year(ages: ages, income_sources: sources)
    assert_equal 0, flows.size
  end

  def test_flow_at_or_after_claiming_age
    ages = { 'Pat' => 70 }
    sources = [{ type: :social_security, recipient: 'Pat', pia_annual: 30000, claiming_age: 67 }]

    flows = Decisions::ClaimSSDecision.decide_for_year(ages: ages, income_sources: sources)
    assert_equal 1, flows.size
    assert_equal 30000, flows.first.amount
    assert_equal 'Pat', flows.first.recipient
  end
end
