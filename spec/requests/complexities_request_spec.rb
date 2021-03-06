# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Complexities", type: :request do
  describe "GET /complexity-of-need/offender-no/:offender_no" do
    let(:offender_no) { complexity.offender_no }

    before do
      get "/complexity-of-need/offender-no/#{offender_no}"
    end

    context "when default" do
      let!(:complexity) {
        create(:complexity)
      }

      it "returns complexity" do
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                   offenderNo: complexity.offender_no,
                   level: complexity.level,
                   sourceSystem: complexity.source_system,
                   createdTimeStamp: JSON.parse(complexity.created_at.to_json),
                 }.to_json))
      end
    end

    context "with all fields populated" do
      let!(:complexity) {
        create(:complexity, :with_user, :with_notes)
      }

      it "returns complexity" do
        expect(response).to have_http_status :ok
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                   sourceUser: complexity.source_user,
                   notes: complexity.notes,
                   offenderNo: complexity.offender_no,
                   level: complexity.level,
                   sourceSystem: complexity.source_system,
                   createdTimeStamp: JSON.parse(complexity.created_at.to_json),
                 }.to_json))
      end
    end

    context "when not found" do
      let(:offender_no) { "non_existent_offender" }

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end

      it "includes an error message" do
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                              message: "No record found for that offender",
                            }.to_json))
      end
    end

    context "with multiple complexity levels in the database" do
      let(:offender_no) { "ABC123" }
      let(:different_offender_no) { "XYZ456" }

      before do
        # Populate database with multiple records for multiple offenders
        [1.month.ago, 1.week.ago, 1.day.ago].each do |date|
          create(:complexity, offender_no: offender_no, created_at: date, updated_at: date)
          create(:complexity, offender_no: different_offender_no, created_at: date, updated_at: date)
        end

        get "/complexity-of-need/offender-no/#{offender_no}"
      end

      it "returns the most recent one for the specified offender" do
        most_recent = Complexity.where(offender_no: offender_no).order(created_at: :desc).first

        expect(JSON.parse(response.body))
            .to eq(JSON.parse({
                                  level: most_recent.level,
                                  offenderNo: offender_no,
                                  createdTimeStamp: most_recent.created_at,
                                  sourceSystem: most_recent.source_system,
                              }.to_json))
      end
    end
  end

  describe "POST /complexity-of-need/offender-no/:offender_no" do
    let(:offender_no) { "ABC123" }

    before do
      post "/complexity-of-need/offender-no/#{offender_no}", params: post_body, as: :json
    end

    context "with only mandatory fields" do
      let(:post_body) {
        {
          level: "high",
        }
      }

      it "creates a new record" do
        expect(response).to have_http_status :ok
        complexity = Complexity.find_by!(offender_no: offender_no)
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                   offenderNo: offender_no,
                   level: post_body.fetch(:level),
                   sourceSystem: "hardcoded-oauth-client-id",
                   createdTimeStamp: complexity.created_at,
                 }.to_json))
      end
    end

    context "with optional fields included" do
      let(:post_body) {
        {
          level: "high",
          sourceUser: "SOME_NOMIS_USER",
          notes: "Some free-text notes supplied by the user",
        }
      }

      it "creates a new record" do
        expect(response).to have_http_status :ok
        complexity = Complexity.find_by!(offender_no: offender_no)
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                              sourceUser: post_body.fetch(:sourceUser),
                              notes: post_body.fetch(:notes),
                              offenderNo: offender_no,
                              level: post_body.fetch(:level),
                              sourceSystem: "hardcoded-oauth-client-id",
                              createdTimeStamp: complexity.created_at,
                            }.to_json))
      end
    end

    context "with mandatory fields missing" do
      let(:post_body) {
        {
          # "level" is missing
          sourceUser: "SOME_NOMIS_USER",
          notes: "Some free-text notes supplied by the user",
        }
      }

      it "returns HTTP 400 Bad Request" do
        expect(response).to have_http_status :bad_request
      end

      it "includes validation errors in the response" do
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                              message: "Validation error",
                              errors: { level: ["Must be low, medium or high"] },
                            }.to_json))
      end
    end

    context "with an invalid complexity level" do
      let(:post_body) {
        {
          level: "something invalid",
        }
      }

      it "returns HTTP 400 Bad Request" do
        expect(response).to have_http_status :bad_request
      end

      it "includes validation errors in the response" do
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                              message: "Validation error",
                              errors: { level: ["Must be low, medium or high"] },
                            }.to_json))
      end
    end
  end
end
