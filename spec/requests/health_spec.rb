# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /ping" do
    it "says pong" do
      get "/ping"
      expect(response).to have_http_status(200)
      expect(response.body).to eq("pong")
    end
  end

  # This is just temporary while the DPS team move over to the new health check
  # They currently only care about the status being 200
  describe "GET /health" do
    it "gets a status 200" do
      get "/health"
      expect(response).to have_http_status(200)
    end
  end
end
