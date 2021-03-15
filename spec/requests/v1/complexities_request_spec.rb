# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Complexities", type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:request_headers) {
    # Include an Authorization header to make the request valid
    { "Authorization" => auth_header }
  }
  let(:topic) { instance_double("topic", publish: nil) }

  before do
    allow(ComplexityEventService).to receive(:sns_topic).and_return(topic)
  end

  describe "GET /v1/complexity-of-need/offender-no/:offender_no" do
    let(:endpoint) { "/v1/complexity-of-need/offender-no/#{offender_no}" }
    let(:offender_no) { complexity.offender_no }

    before do
      get endpoint, headers: request_headers
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

        get endpoint, headers: request_headers
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

    context "when the client doesn't have the 'read' scope" do
      let(:offender_no) { "ABC123" }

      before do
        stub_access_token scopes: []
        get endpoint, headers: request_headers
      end

      it "returns HTTP 403 Forbidden" do
        expect(response).to have_http_status :forbidden
      end

      it "includes validation errors in the response" do
        expect(response_json)
          .to eq json_object(message: "You need the scope 'read' to use this endpoint")
      end
    end

    context "when the client is unauthenticated" do
      let(:offender_no) { "ABC123" }

      before do
        get endpoint # don't include an Authorization header
      end

      it "returns HTTP 401 Unauthorized" do
        expect(response).to have_http_status :unauthorized
      end

      it "includes validation errors in the response" do
        expect(response_json)
          .to eq json_object(message: "Missing or invalid access token")
      end
    end

    context "when the client's token has expired" do
      let(:offender_no) { "ABC123" }

      before do
        # Travel into the future to expire the access token
        Timecop.travel(Time.zone.today + 1.year) do
          get endpoint, headers: request_headers
        end
      end

      it "returns HTTP 401 Unauthorized" do
        expect(response).to have_http_status :unauthorized
      end

      it "includes validation errors in the response" do
        expect(response_json)
          .to eq json_object(message: "Missing or invalid access token")
      end
    end
  end

  describe "POST /v1/complexity-of-need/offender-no/:offender_no" do
    let(:endpoint) { "/v1/complexity-of-need/offender-no/#{offender_no}" }
    let(:offender_no) { "ABC123" }

    before do
      post endpoint, params: post_body, as: :json, headers: request_headers
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

    context "without role ROLE_COMPLEXITY_OF_NEED" do
      let(:post_body) { nil }

      before do
        stub_access_token scopes: %w[read write], roles: %w[SOME_OTHER_ROLE]
        post endpoint, params: post_body, as: :json, headers: request_headers
      end

      it "returns HTTP 403 Forbidden" do
        expect(response).to have_http_status :forbidden
      end

      it "includes validation errors in the response" do
        expect(response_json)
          .to eq json_object(message: "You need the role 'ROLE_COMPLEXITY_OF_NEED' with scope 'write' to use this endpoint")
      end
    end

    context "without write scope" do
      let(:post_body) { nil }

      before do
        stub_access_token scopes: %w[read], roles: %w[ROLE_COMPLEXITY_OF_NEED]
        post endpoint, params: post_body, as: :json, headers: request_headers
      end

      it "returns HTTP 403 Forbidden" do
        expect(response).to have_http_status :forbidden
      end

      it "includes validation errors in the response" do
        expect(response_json)
          .to eq json_object(message: "You need the role 'ROLE_COMPLEXITY_OF_NEED' with scope 'write' to use this endpoint")
      end
    end
  end

  describe "POST /v1/complexity-of-need/multiple/offender-no" do
    let(:endpoint) { "/v1/complexity-of-need/multiple/offender-no" }

    context "with a missing or invalid request body" do
      before do
        post endpoint, headers: request_headers
      end

      it "returns HTTP 400 Bad Request" do
        expect(response).to have_http_status :bad_request
      end

      it "includes an error message" do
        expect(response_json)
          .to eq json_object(message: "You must provide a JSON array of NOMIS Offender Numbers in the request body")
      end
    end

    context "with an empty array" do
      before do
        post endpoint, params: [], as: :json, headers: request_headers
      end

      it "returns an empty result set" do
        expect(response_json).to eq json_object([])
      end
    end

    context "with multiple offender numbers" do
      let(:offender_with_multiple_levels) { "Offender1" }
      let(:offender_with_one_level) { "Offender2" }
      let(:offender_without_levels) { "Offender3" }

      let(:expected_response) {
        [offender_with_one_level, offender_with_multiple_levels].map do |offender|
          # Find the most recent Complexity for this offender
          most_recent = Complexity.order(created_at: :desc).where(offender_no: offender).first
          {
            offenderNo: offender,
            level: most_recent.level,
            sourceSystem: most_recent.source_system,
            sourceUser: most_recent.source_user,
            notes: most_recent.notes,
            createdTimeStamp: most_recent.created_at,
          }.compact # Remove nil values – sourceUser and notes are optional
        end
      }

      let(:post_body) { [offender_with_one_level, offender_with_multiple_levels, offender_without_levels] }

      before do
        create_list(:complexity, 10, :random_date, offender_no: offender_with_multiple_levels)
        create(:complexity, :random_date, :with_user, :with_notes, offender_no: offender_with_one_level)

        post endpoint, params: post_body, as: :json, headers: request_headers
      end

      it "returns an array of the current Complexity level for each offender" do
        expect(response_json).to match_array json_object(expected_response)
      end

      it "does not include offenders who don't have a Complexity level" do
        returned_offenders = response_json.map { |complexity| complexity.fetch("offenderNo") }
        expect(returned_offenders).not_to include(offender_without_levels)
      end
    end

    context "with lots of offenders" do
      # Generate 1000 offender numbers
      let(:offenders) { (1..1000).map { |n| "Offender#{n}" } }

      let(:expected_response) {
        offenders.map do |offender|
          # Find the most recent Complexity for this offender
          most_recent = Complexity.order(created_at: :desc).where(offender_no: offender).first
          {
            offenderNo: offender,
            level: most_recent.level,
            sourceSystem: most_recent.source_system,
            createdTimeStamp: most_recent.created_at,
          }
        end
      }

      before do
        # Generate a Complexity for each offender
        offenders.each { |offender|
          create(:complexity, :random_date, offender_no: offender)
        }

        post endpoint, params: offenders, as: :json, headers: request_headers
      end

      it "returns all records without paginating" do
        expect(response_json).to match_array json_object(expected_response)
      end
    end

    context "when the client doesn't have the 'read' scope" do
      before do
        stub_access_token scopes: []
        post endpoint, params: [], as: :json, headers: request_headers
      end

      it "returns HTTP 403 Forbidden" do
        expect(response).to have_http_status :forbidden
      end

      it "includes validation errors in the response" do
        expect(response_json)
          .to eq json_object(message: "You need the scope 'read' to use this endpoint")
      end
    end
  end

  describe "GET /v1/complexity-of-need/offender-no/:offender_no/history" do
    let(:endpoint) { "/v1/complexity-of-need/offender-no/#{offender_no}/history" }
    let(:different_offender_no) { "XYZ456" }

    before do
      get endpoint, headers: request_headers
    end

    context "when offender not found" do
      let(:offender_no) { "non_existent_offender" }

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end

      it "includes an error message" do
        expect(response_json).to eq json_object(message: "No record found for that offender")
      end
    end

    context "with a single entry" do
      let!(:complexity) { create(:complexity) }
      let(:offender_no) { complexity.offender_no }

      it "returns an array" do
        expect(response_json).to be_an(Array)
      end

      it "returns the single complexity record" do
        expect(response_json.size).to eq 1
        expect(response_json.first).to eq json_object(level: complexity.level,
                                                      offenderNo: complexity.offender_no,
                                                      createdTimeStamp: complexity.created_at,
                                                      sourceSystem: complexity.source_system)
      end
    end

    context "with multiple entries" do
      let(:offender_no) { "1234567" }

      before do
        # Populate database with multiple records for multiple offenders
        [1.month.ago, 3.weeks.ago, 1.week.ago, 1.day.ago].each do |date|
          create(:complexity, created_at: date, updated_at: date)
          create(:complexity, offender_no: different_offender_no, created_at: date, updated_at: date)
        end

        get endpoint, headers: request_headers
      end

      it "returns an array" do
        expect(response_json).to be_an(Array)
        expect(response_json.size).to eq 4
      end

      it "displays all the records for the offender in descending order" do
        history = Complexity.order(created_at: :desc).where(offender_no: offender_no)

        response_json.each_with_index do |json, index|
          expect(json).to eq json_object(level: history[index].level,
                                         offenderNo: history[index].offender_no,
                                         createdTimeStamp: history[index].created_at,
                                         sourceSystem: history[index].source_system)
        end
      end
    end

    context "when the client doesn't have the 'read' scope" do
      let(:offender_no) { "1234567" }

      before do
        stub_access_token scopes: []
        get endpoint, headers: request_headers
      end

      it "returns HTTP 403 Forbidden" do
        expect(response).to have_http_status :forbidden
      end

      it "includes validation errors in the response" do
        expect(response_json)
          .to eq json_object(message: "You need the scope 'read' to use this endpoint")
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
