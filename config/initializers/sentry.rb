# frozen_string_literal: true

Sentry.init do |config|
  # 'DSN' and 'environment' are automatically pulled in from
  # environment variables SENTRY_DSN and SENTRY_CURRENT_ENV
  # so no need to configure them here

  config.breadcrumbs_logger = [:active_support_logger]
  config.release = ENV["BUILD_NUMBER"]
end
