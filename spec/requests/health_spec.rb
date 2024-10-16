# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health", type: :request do
  let(:build_number) { "2014-12-25.52422.e70d4e2" }
  let(:git_ref) { "e70d4e2" }

  describe "GET /ping" do
    it "says pong" do
      get "/ping"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("pong")
    end
  end

  describe "GET /health/ping" do
    it "says pong" do
      get "/health/ping"
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("pong")
    end
  end

  # rubocop:disable RSpec/ExampleLength
  describe "GET /health" do
    let(:auth_client) { instance_double(HmppsApi::Oauth::Client) }

    before do
      allow(HmppsApi::Oauth::Client).to receive(:new).and_return(auth_client)
      allow(auth_client).to receive(:raw_get).with("/auth/ping").and_return("pong")

      stub_const(
        "ENV",
        ENV.to_hash.merge(
          "BUILD_NUMBER" => build_number,
          "GIT_REF" => git_ref,
        ),
      )

      Rails.configuration.x.init_epoch = 123.seconds.ago.to_i
    end

    it "returns health check status and information regarding the deployed application" do
      get "/health"

      expect(JSON.parse(response.body)).to eq(
        {
          status: "UP",
          components: { "db" => { "status" => "UP" }, "hmppsAuth" => { "status" => "UP" } },
          uptime: 123,
          build: {
            "buildNumber" => build_number,
            "gitRef" => git_ref,
          },
          version: build_number,
        }.deep_stringify_keys,
      )
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
