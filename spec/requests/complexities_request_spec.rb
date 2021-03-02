# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Complexities", type: :request do
  context "when default" do
    let!(:complexity) {
      create(:complexity)
    }

    it "returns complexity" do
      get "/complexity-of-need/offender-no/#{complexity.offender_no}.json"

      expect(response).to have_http_status :ok
      expect(JSON.parse(response.body))
          .to eq({
                   offenderNo: complexity.offender_no,
                   level: complexity.level,
                   sourceSystem: complexity.source_system,
                   createdTimeStamp: JSON.parse(complexity.created_at.to_json),
                 }.stringify_keys)
    end
  end

  context "when not found" do
    it "returns 404" do
      get "/complexity-of-need/offender-no/27.json"

      expect(response).to have_http_status :not_found
    end
  end

  context "with a source user" do
    let!(:complexity) {
      create(:complexity, :with_user)
    }

    it "returns complexity" do
      get "/complexity-of-need/offender-no/#{complexity.offender_no}.json"

      expect(response).to have_http_status :ok
      expect(JSON.parse(response.body))
          .to eq({
                   sourceUser: complexity.source_user,
                   offenderNo: complexity.offender_no,
                   level: complexity.level,
                   sourceSystem: complexity.source_system,
                   createdTimeStamp: JSON.parse(complexity.created_at.to_json),
                 }.stringify_keys)
    end
  end
end
