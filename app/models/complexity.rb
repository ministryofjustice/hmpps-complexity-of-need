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
    offender_nos.map { |n| latest_for_offender(n) }.compact
  end

  def self.latest_for_offender(offender_no)
    cnl = where(offender_no: offender_no).order(created_at: :desc).limit(1).first
    cnl.present? && cnl.active? ? cnl : nil
  end
end
