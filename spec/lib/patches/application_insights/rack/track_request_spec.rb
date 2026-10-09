require "rails_helper"
require "application_insights"
require "rack/mock"
require Rails.root.join("lib/patches/application_insights/track_request")

ApplicationInsights::Rack::TrackRequest.prepend(Patches::ApplicationInsights::TrackRequest) unless
  ApplicationInsights::Rack::TrackRequest < Patches::ApplicationInsights::TrackRequest

RSpec.describe ApplicationInsights::Rack::TrackRequest do
  def build_route(template)
    Struct.new(:path).new(Struct.new(:spec).new(template))
  end

  subject(:middleware) do
    described_class.allocate.tap do |instance|
      instance.instance_variable_set(:@app, app)
      instance.instance_variable_set(:@instrumentation_key, "test-key")
      instance.instance_variable_set(:@client, client)
    end
  end

  let(:app) do
    ->(_env) { [200, { "Content-Type" => "text/plain" }, %w[ok]] }
  end
  let(:channel) { instance_double(ApplicationInsights::Channel::TelemetryChannel, write: true) }
  let(:client) { instance_double(ApplicationInsights::TelemetryClient, channel:, track_exception: nil) }

  describe "#call" do
    it "uses the Rails route template for the request name when available" do
      env = Rack::MockRequest.env_for("/v1/complexity-of-need/offender-no/A1234BC").merge(
        "action_dispatch.route" => build_route("/v1/complexity-of-need/offender-no/:offender_no(.:format)"),
      )

      middleware.call(env)

      expect(channel).to have_received(:write) do |data, _context, _time|
        expect(data.name).to eq("GET /v1/complexity-of-need/offender-no/:offender_no")
      end
    end

    it "falls back to the raw request path when no route template is available" do
      env = Rack::MockRequest.env_for("/v1/complexity-of-need/offender-no/A1234BC")

      middleware.call(env)

      expect(channel).to have_received(:write) do |data, _context, _time|
        expect(data.name).to eq("GET /v1/complexity-of-need/offender-no/A1234BC")
      end
    end

    it "falls back to the raw request path for a catch-all route" do
      env = Rack::MockRequest.env_for("/missing/path").merge(
        "action_dispatch.route" => build_route("/*path(.:format)"),
      )

      middleware.call(env)

      expect(channel).to have_received(:write) do |data, _context, _time|
        expect(data.name).to eq("GET /missing/path")
      end
    end

    it "does not track ignored paths" do
      responses = %w[/info /health /health/ping].map do |path|
        env = Rack::MockRequest.env_for(path)

        middleware.call(env)
      end

      expect(responses).to all(eq([200, { "Content-Type" => "text/plain" }, %w[ok]]))
      expect(channel).not_to have_received(:write)
    end
  end
end
