# frozen_string_literal: true

require "rails_helper"

describe "Info endpoints" do
  describe "GET /info" do
    before do
      stub_const(
        "ENV", {
          "GIT_BRANCH" => "main",
          "BUILD_NUMBER" => "af79nbc",
          "PRODUCT_ID" => "PROD1",
        }
      )

      get "/info"
    end

    it "returns information regarding the deployed application" do
      expect(
        response.body,
      ).to eq('{"git":{"branch":"main"},"build":{"artifact":"hmpps-complexity-of-need","version":"af79nbc","name":"hmpps-complexity-of-need"},"productId":"PROD1"}')
    end
  end
end
