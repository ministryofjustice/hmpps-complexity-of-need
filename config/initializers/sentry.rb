# frozen_string_literal: true

sentry_dsn = Rails.configuration.sentry_dsn

if sentry_dsn.present?
  require "active_support/parameter_filter"
  param_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

  Sentry.init do |config|
    config.dsn = sentry_dsn
    config.release = ENV["BUILD_NUMBER"]
    config.enable_metrics = false
    config.rails.report_rescued_exceptions = false

    if Rails.env.development?
      config.background_worker_threads = 0
      config.sdk_logger = Sentry::Logger.new($stdout).tap { it.level = Logger::DEBUG }
    end

    config.excluded_exceptions += %w[
      JWT::ExpiredSignature
      JWT::VerificationError
      ActiveRecord::RecordNotFound
      ActionController::RoutingError
      ActionController::UnknownFormat
      ActionController::InvalidAuthenticityToken
      ActionController::BadRequest
      Faraday::ConnectionFailed
      Faraday::TimeoutError
    ]

    config.before_send = lambda do |event, hint|
      begin
        # Sanitize extra data
        if event.extra
          event.extra = param_filter.filter(event.extra)
        end

        # Sanitize user data
        if event.user
          event.user = param_filter.filter(event.user)
        end

        # Sanitize context data
        if event.contexts
          event.contexts = param_filter.filter(event.contexts)
        end
      rescue StandardError => e
        Rails.logger.warn(
          "event=sentry_sanitization_error|original_exception_class=#{hint[:exception]&.class}|#{e.message}",
        )
      end

      # Return the sanitized event object
      event
    end
  end
else
  Rails.logger.warn "[WARN] Sentry is not configured (SENTRY_DSN)"
end
