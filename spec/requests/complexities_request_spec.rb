# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Complexities", type: :request do
  let(:response_json) { JSON.parse(response.body) }

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
        expect(response_json)
          .to eq json_object(offenderNo: complexity.offender_no,
                             level: complexity.level,
                             sourceSystem: complexity.source_system,
                             createdTimeStamp: complexity.created_at)
      end
    end

    context "with all fields populated" do
      let!(:complexity) {
        create(:complexity, :with_user, :with_notes)
      }

      it "returns complexity" do
        expect(response).to have_http_status :ok
        expect(response_json)
          .to eq json_object(sourceUser: complexity.source_user,
                             notes: complexity.notes,
                             offenderNo: complexity.offender_no,
                             level: complexity.level,
                             sourceSystem: complexity.source_system,
                             createdTimeStamp: complexity.created_at)
      end
    end

    context "when not found" do
      let(:offender_no) { "non_existent_offender" }

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end

      it "includes an error message" do
        expect(response_json)
          .to eq json_object(message: "No record found for that offender")
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

        expect(response_json)
            .to eq json_object(level: most_recent.level,
                               offenderNo: offender_no,
                               createdTimeStamp: most_recent.created_at,
                               sourceSystem: most_recent.source_system)
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
        expect(response_json)
          .to eq json_object(offenderNo: offender_no,
                             level: post_body.fetch(:level),
                             sourceSystem: "hardcoded-oauth-client-id",
                             createdTimeStamp: complexity.created_at)
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
        expect(response_json)
          .to eq json_object(sourceUser: post_body.fetch(:sourceUser),
                             notes: post_body.fetch(:notes),
                             offenderNo: offender_no,
                             level: post_body.fetch(:level),
                             sourceSystem: "hardcoded-oauth-client-id",
                             createdTimeStamp: complexity.created_at)
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
        expect(response_json)
          .to eq json_object(message: "Validation error",
                             errors: { level: ["Must be low, medium or high"] })
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
        expect(response_json)
          .to eq json_object(message: "Validation error",
                             errors: { level: ["Must be low, medium or high"] })
      end
    end
  end

private

  # Run the supplied object through a JSON encode/decode cycle
  # Useful when comparing non-string values against a JSON response
  # e.g. date objects will be serialized and re-hydrated as strings
  def json_object(object)
    JSON.parse(object.to_json)
  end
end
