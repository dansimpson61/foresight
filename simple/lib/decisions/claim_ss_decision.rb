require_relative '../flows/social_security_flow'

module Foresight
  module Simple
    module Decisions
      # ClaimSSDecision — pure helper to propose Social Security flows for the year.
      # Contract: decide_for_year(ages:, income_sources:) -> [SocialSecurityFlow]
      # Current policy: claim at configured claiming_age, per income source.
      class ClaimSSDecision
        def self.decide_for_year(ages:, income_sources:)
          return [] unless income_sources && !income_sources.empty?

          ss_sources = income_sources.select { |s| s[:type].to_sym == :social_security }
          ss_sources.flat_map do |src|
            recipient = src[:recipient]
            claiming_age = src[:claiming_age]
            amount = src[:pia_annual]
            next [] unless recipient && claiming_age && amount

            recipient_age = ages[recipient]
            next [] unless recipient_age && recipient_age >= claiming_age

            [SocialSecurityFlow.new(amount: amount, recipient: recipient)]
          end
        end
      end
    end
  end
end
