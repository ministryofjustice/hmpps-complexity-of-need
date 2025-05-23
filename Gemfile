# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

gem "rails", "~> 7.1.3"

gem "aws-sdk-sns"
gem "faraday"
gem "jbuilder", "~> 2.7"
gem "jwt"
gem "ostruct"
gem "pg", "~> 1.1"
gem "puma", "~> 6.6.0"
gem "responders"
gem "rswag-api"
gem "rswag-ui"

# Microsoft Application Insights
gem "application_insights"

# Veracode static code analysis
gem "veracode"

# Sentry error reporting
gem "sentry-rails"
gem "sentry-ruby"

# Logging
gem "lograge"
gem "logstash-event"

group :development, :test do
  gem "brakeman"
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "rswag-specs"
  gem "rubocop"
  gem "rubocop-govuk"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rspec"
end

group :test do
  gem "rspec_junit_formatter"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "simplecov-lcov", require: false
  gem "undercover"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
