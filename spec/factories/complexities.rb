# frozen_string_literal: true

FactoryBot.define do
  factory :complexity do
    offender_no { "1234567" }
    level { Complexity::VALID_LEVELS.sample }
    source_system { "omic-mpc-something" }

    # Complexity records are never edited, so updated_at should always equal created_at
    updated_at { created_at }

    trait :with_user do
      source_user { "A_NOMIS_USER" }
    end

    trait :with_notes do
      notes { "Some reason why this level was given" }
    end

    # Set created_at to a random date in the past
    trait :random_date do
      created_at { Kernel.rand(1.year.ago..1.minute.ago) }
    end
  end
end
