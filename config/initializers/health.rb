require "health"

config = Rails.configuration

# Used in the health endpoint to calculate instance uptime
config.x.init_epoch = Time.zone.now.to_i

config.x.health_checks = Health.new(timeout_in_seconds_per_check: 2, num_retries_per_check: 2)
  .add_check(
    name: "db",
    get_response: -> { ActiveRecord::Base.connection.active? },
    check_response: ->(response) { response == true },
  )
  .add_check(
    name: "hmppsAuth",
    get_response: -> { HmppsApi::Oauth::Client.new(config.nomis_oauth_host).raw_get("/auth/ping") },
    check_response: ->(response) { response == "pong" },
  )
