# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /health" do
    it "says that eveything is ok" do
      get "/health"
      expect(response).to have_http_status(200)
      expect(response.body).to eq("Everything is fine.")
    end
  end
end
