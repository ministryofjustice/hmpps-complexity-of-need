require "rails_helper"

RSpec.describe Sentry do
  let(:sentry_dsn) { "https://examplePublicKey@o0.ingest.sentry.io/0" }
  let(:rails_config) { instance_double(Sentry::Rails::Configuration) }
  let(:config_class) do
    Struct.new(:dsn, :release, :enable_metrics, :excluded_exceptions, :before_send, :rails, keyword_init: true)
  end
  let(:config) { config_class.new(excluded_exceptions: [], rails: rails_config) }

  before do
    allow(rails_config).to receive(:report_rescued_exceptions=)
    allow(Rails.configuration).to receive(:sentry_dsn).and_return(sentry_dsn)
    allow(described_class).to receive(:init).and_yield(config)
  end

  it "configures the essential Sentry settings" do
    load Rails.root.join("config/initializers/sentry.rb")

    expect(config).to have_attributes(
      dsn: sentry_dsn,
      release: ENV["BUILD_NUMBER"],
      enable_metrics: false,
    )
  end

  it "disables reporting rescued exceptions via the Rails integration" do
    load Rails.root.join("config/initializers/sentry.rb")

    expect(rails_config).to have_received(:report_rescued_exceptions=).with(false)
  end

  it "configures the expected excluded exceptions" do
    load Rails.root.join("config/initializers/sentry.rb")

    expect(config.excluded_exceptions).to include("JWT::ExpiredSignature", "Faraday::TimeoutError")
  end

  context "when the Sentry DSN is blank" do
    let(:sentry_dsn) { "" }

    it "logs a warning and skips Sentry initialisation" do
      allow(Rails.logger).to receive(:warn)

      load Rails.root.join("config/initializers/sentry.rb")

      expect(described_class).not_to have_received(:init)
      expect(Rails.logger).to have_received(:warn)
    end
  end
end
