# frozen_string_literal: true

class Complexity < ApplicationRecord
  after_save do |complexity|
    ComplexityEventService.send_complexity(complexity)
  end
  VALID_LEVELS = %w[low medium high].freeze

  validates :offender_no, presence: true
  validates :level, inclusion: {
    in: VALID_LEVELS,
    allow_nil: false,
    message: "Must be low, medium or high",
  }

  # Get the latest/current Complexity for the given offenders
  def self.latest_for_offenders(offender_nos)
    where(offender_no: offender_nos)
      .order(created_at: :desc)
      .group_by(&:offender_no)
      .transform_values(&:first)
      .values.select(&:active?)
  end
end
