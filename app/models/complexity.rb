# frozen_string_literal: true

class Complexity < ApplicationRecord
  VALID_LEVELS = %w[low medium high].freeze

  validates :offender_no, presence: true
  validates :level, inclusion: {
    in: VALID_LEVELS, allow_nil: false,
    message: "Must be low, medium or high"
  }
end
