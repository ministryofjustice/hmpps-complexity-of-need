# frozen_string_literal: true

FactoryBot.define do
  factory :complexity do
    offender_no { "1234567" }
    level { "high" }
    source_system { "omic-mpc-something" }

    trait :with_user do
      source_user { "A_NOMIS_USER" }
    end
  end
end
