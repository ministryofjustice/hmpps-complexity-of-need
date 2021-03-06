# frozen_string_literal: true

FactoryBot.define do
  factory :complexity do
    offender_no { "1234567" }
    level { Complexity::VALID_LEVELS.sample }
    source_system { "omic-mpc-something" }

    trait :with_user do
      source_user { "A_NOMIS_USER" }
    end

    trait :with_notes do
      notes { "Some reason why this level was given" }
    end
  end
end
