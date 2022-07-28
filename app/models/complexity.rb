# frozen_string_literal: true

class Complexity < ApplicationRecord
  after_save do |complexity|
    ComplexityEventService.send_complexity(complexity)
  end
  VALID_LEVELS = %w[low medium high].freeze

  scope :active, -> { where(active: true) }

  validates :offender_no, presence: true
  validates :level, inclusion: {
    in: VALID_LEVELS,
    allow_nil: false,
    message: "Must be low, medium or high",
  }

  # Get the latest/current Complexity for the given offenders
  def self.latest_for_offenders(offender_nos)
    self.active
        .select("DISTINCT ON (offender_no) *")
        .order(:offender_no, created_at: :desc)
        .where(offender_no: offender_nos)
  end
end
