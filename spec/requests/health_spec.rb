# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /ping" do
    it "says ping" do
      get "/ping"
      expect(response).to have_http_status(200)
      expect(response.body).to eq("pong")
    end
  end
end
