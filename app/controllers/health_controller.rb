# frozen_string_literal: true

class HealthController < ApplicationController
  def index
    render json: {
      **health_checks.status,
      uptime:,
      build: {
        "buildNumber" => ENV["BUILD_NUMBER"],
        "gitRef" => ENV["GIT_REF"],
      },
      version: ENV["BUILD_NUMBER"],
    }
  end

  def ping
    render plain: "pong"
  end

private

  def uptime
    Time.zone.now.to_i - Rails.configuration.x.init_epoch
  end

  def health_checks
    Rails.configuration.x.health_checks
  end
end
