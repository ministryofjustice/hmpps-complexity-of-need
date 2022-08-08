# frozen_string_literal: true

require "rails_helper"

shared_examples "HTTP 403 Forbidden" do |error_message|
  it "returns HTTP 403 Forbidden" do
    expect(response).to have_http_status :forbidden
  end

  it "includes validation errors in the response" do
    expect(response_json).to eq json_object(message: error_message)
  end
end

shared_examples "HTTP 401 Unauthorized" do
  it "returns HTTP 401 Unauthorized" do
    expect(response).to have_http_status :unauthorized
  end

  it "includes validation errors in the response" do
    expect(response_json).to eq json_object(message: "Missing or invalid access token")
  end
end

RSpec.describe "Complexities", type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:request_headers) do
    # Include an Authorization header to make the request valid
    { "Authorization" => auth_header }
  end
  let(:topic) { instance_double("topic", publish: nil) }

  before do
    allow(ComplexityEventService).to receive(:sns_topic).and_return(topic)
  end

  describe "GET /v1/complexity-of-need/offender-no/:offender_no" do
    let(:endpoint) { "/v1/complexity-of-need/offender-no/#{offender_no}" }
    let(:offender_no) { complexity.offender_no }
    let!(:complexity) { create(:complexity) }

    before do
      get endpoint, headers: request_headers
    end

    context "when default" do
      it "returns complexity" do
        expect(response).to have_http_status :ok
        expect(response_json)
          .to eq json_object(offenderNo: complexity.offender_no,
                             level: complexity.level,
                             sourceSystem: complexity.source_system,
                             createdTimeStamp: complexity.created_at,
                             active: complexity.active)
      end
    end

    context "with all fields populated" do
      let!(:complexity) { create(:complexity, :with_user, :with_notes) }

      it "returns complexity" do
        expect(response).to have_http_status :ok
        expect(response_json)
          .to eq json_object(sourceUser: complexity.source_user,
                             notes: complexity.notes,
                             offenderNo: complexity.offender_no,
                             level: complexity.level,
                             sourceSystem: complexity.source_system,
                             createdTimeStamp: complexity.created_at,
                             active: complexity.active)
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
      let(:complexity) { nil }
      let(:offender_no) { "ABC123" }
      let(:different_offender_no) { "XYZ456" }
      let(:most_recent) { Complexity.where(offender_no: offender_no).order(created_at: :desc).first }
      let(:most_recent_active_status) { true }


      before do
        # Populate database with multiple records for multiple offenders
        [1.month.ago, 1.week.ago, 1.day.ago].each do |date|
          create(:complexity, offender_no: offender_no, created_at: date, updated_at: date)
          create(:complexity, offender_no: different_offender_no, created_at: date, updated_at: date)
        end

        most_recent.update(active: most_recent_active_status)

        get endpoint, headers: request_headers
      end

      it "returns the most recent one for the specified offender" do
        expect(response_json)
            .to eq json_object(level: most_recent.level,
                               offenderNo: offender_no,
                               createdTimeStamp: most_recent.created_at,
                               sourceSystem: most_recent.source_system,
                               active: most_recent.active)
      end

      context 'and with the latest complexity inactive' do
        let(:most_recent_active_status) { false }
        let(:most_recent_active) { Complexity.active.where(offender_no: offender_no).order(created_at: :desc).first }

        it "returns 404" do
          expect(response).to have_http_status :not_found
        end
      end
    end

    context "when the client doesn't have the 'read' scope" do
      before do
        stub_access_token scopes: []
        get endpoint, headers: request_headers
      end

      include_examples "HTTP 403 Forbidden", "You need the role 'ROLE_COMPLEXITY_OF_NEED' to use this endpoint"
    end

    context "when the client is unauthenticated" do
      before do
        get endpoint # don't include an Authorization header
      end

      include_examples "HTTP 401 Unauthorized"
    end

    context "when the client's token has expired" do
      before do
        # Travel into the future to expire the access token
        Timecop.travel(Time.zone.today + 1.year) do
          get endpoint, headers: request_headers
        end
      end

      include_examples "HTTP 401 Unauthorized"
    end
  end

  describe "POST /v1/complexity-of-need/offender-no/:offender_no" do
    let(:endpoint) { "/v1/complexity-of-need/offender-no/#{offender_no}" }
    let(:offender_no) { "ABC123" }
    let(:source_system) { Rails.configuration.nomis_oauth_client_id }

    context "with only mandatory fields" do
      let(:post_body) do
        {
          level: "high",
        }
      end

      before do
        post endpoint, params: post_body, as: :json, headers: request_headers
      end

      it "creates a new record" do
        expect(response).to have_http_status :ok
        complexity = Complexity.find_by!(offender_no: offender_no)
        expect(response_json)
          .to eq json_object(offenderNo: offender_no,
                             level: post_body.fetch(:level),
                             sourceSystem: source_system,
                             createdTimeStamp: complexity.created_at,
                             active: complexity.active)
      end
    end

    context "with optional fields included" do
      let(:post_body) do
        {
          level: "high",
          sourceUser: "SOME_NOMIS_USER",
          notes: "Some free-text notes supplied by the user",
        }
      end

      before do
        post endpoint, params: post_body, as: :json, headers: request_headers
      end

      it "creates a new record" do
        expect(response).to have_http_status :ok
        complexity = Complexity.find_by!(offender_no: offender_no)
        expect(response_json)
          .to eq json_object(sourceUser: post_body.fetch(:sourceUser),
                             notes: post_body.fetch(:notes),
                             offenderNo: offender_no,
                             level: post_body.fetch(:level),
                             sourceSystem: source_system,
                             createdTimeStamp: complexity.created_at,
                             active: complexity.active)
      end
    end

    context "with mandatory fields missing" do
      let(:post_body) do
        {
          # "level" is missing
          sourceUser: "SOME_NOMIS_USER",
          notes: "Some free-text notes supplied by the user",
        }
      end

      before do
        post endpoint, params: post_body, as: :json, headers: request_headers
      end

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
      let(:post_body) do
        {
          level: "something invalid",
        }
      end

      before do
        post endpoint, params: post_body, as: :json, headers: request_headers
      end

      it "returns HTTP 400 Bad Request" do
        expect(response).to have_http_status :bad_request
      end

      it "includes validation errors in the response" do
        expect(response_json)
          .to eq json_object(message: "Validation error",
                             errors: { level: ["Must be low, medium or high"] })
      end
    end

    context "without role ROLE_UPDATE_COMPLEXITY_OF_NEED" do
      before do
        stub_access_token scopes: %w[read write], roles: %w[ROLE_COMPLEXITY_OF_NEED]
        post endpoint, headers: request_headers
      end

      include_examples "HTTP 403 Forbidden",
                       "You need the role 'ROLE_UPDATE_COMPLEXITY_OF_NEED' to use this endpoint"
    end

    context "when the client is unauthenticated" do
      before do
        post endpoint # don't include an Authorization header
      end

      include_examples "HTTP 401 Unauthorized"
    end

    context "when the client's token has expired" do
      before do
        # Travel into the future to expire the access token
        Timecop.travel(Time.zone.today + 1.year) do
          post endpoint, headers: request_headers
        end
      end

      include_examples "HTTP 401 Unauthorized"
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

      let(:expected_response) do
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
            active: most_recent.active
          }.compact # Remove nil values – sourceUser and notes are optional
        end
      end

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

      let(:expected_response) do
        offenders.map do |offender|
          # Find the most recent Complexity for this offender
          most_recent = Complexity.order(created_at: :desc).where(offender_no: offender).first
          {
            offenderNo: offender,
            level: most_recent.level,
            sourceSystem: most_recent.source_system,
            createdTimeStamp: most_recent.created_at,
            active: most_recent.active
          }
        end
      end

      before do
        # Generate a Complexity for each offender
        offenders.each do |offender|
          create(:complexity, :random_date, offender_no: offender)
        end

        post endpoint, params: offenders, as: :json, headers: request_headers
      end

      it "returns all records without paginating" do
        expect(response_json).to match_array json_object(expected_response)
      end
    end

    context "when the client doesn't have the 'read' scope" do
      before do
        stub_access_token scopes: []
        post endpoint, headers: request_headers
      end

      include_examples "HTTP 403 Forbidden", "You need the role 'ROLE_COMPLEXITY_OF_NEED' to use this endpoint"
    end

    context "when the client is unauthenticated" do
      before do
        post endpoint # don't include an Authorization header
      end

      include_examples "HTTP 401 Unauthorized"
    end

    context "when the client's token has expired" do
      let(:token_is_expired) { true }

      before do
        # Travel into the future to expire the access token
        Timecop.travel(Time.zone.today + 1.year) do
          post endpoint, headers: request_headers
        end
      end

      include_examples "HTTP 401 Unauthorized"
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
                                                      sourceSystem: complexity.source_system,
                                                      active: complexity.active)
      end
    end

    context "with multiple entries" do
      let(:offender_no) { "1234567" }
      let(:history) { Complexity.order(created_at: :desc).where(offender_no: offender_no) }
      let(:some_inactive) { false }

      before do
        # Populate database with multiple records for multiple offenders
        [1.month.ago, 3.weeks.ago, 1.week.ago, 1.day.ago].each_with_index do |date, i|
          create(:complexity, offender_no: offender_no, created_at: date, updated_at: date, active: some_inactive ? i.odd? : true)
          create(:complexity, offender_no: different_offender_no, created_at: date, updated_at: date)
        end

        get endpoint, headers: request_headers
      end

      it "returns an array" do
        expect(response_json).to be_an(Array)
        expect(response_json.size).to eq 4
      end

      it "displays all the records for the offender in descending order" do
        response_json.each_with_index do |json, index|
          expect(json).to eq json_object(level: history[index].level,
                                         offenderNo: history[index].offender_no,
                                         createdTimeStamp: history[index].created_at,
                                         sourceSystem: history[index].source_system,
                                         active: history[index].active)
        end
      end

      context 'with some inactivated' do
        let(:some_inactive) { true }

        it "displays all the records including inactivated" do
          response_json.each_with_index do |json, index|
            expect(json).to eq json_object(level: history[index].level,
                                          offenderNo: history[index].offender_no,
                                          createdTimeStamp: history[index].created_at,
                                          sourceSystem: history[index].source_system,
                                          active: history[index].active)
          end
        end
      end
    end

    context "when the client doesn't have the 'read' scope" do
      let(:offender_no) { "1234567" }

      before do
        stub_access_token scopes: []
        get endpoint, headers: request_headers
      end

      include_examples "HTTP 403 Forbidden", "You need the role 'ROLE_COMPLEXITY_OF_NEED' to use this endpoint"
    end

    context "when the client is unauthenticated" do
      let(:offender_no) { "1234567" }

      before do
        get endpoint # don't include an Authorization header
      end

      include_examples "HTTP 401 Unauthorized"
    end

    context "when the client's token has expired" do
      let(:offender_no) { "1234567" }

      before do
        # Travel into the future to expire the access token
        Timecop.travel(Time.zone.today + 1.year) do
          get endpoint, headers: request_headers
        end
      end

      include_examples "HTTP 401 Unauthorized"
    end

  end

  describe "PUT /v1/complexity-of-need/offender-no/:offender_no/inactivate" do
    let(:endpoint) { "/v1/complexity-of-need/offender-no/#{offender_no}/inactivate" }
    let(:offender_no) { complexity.offender_no }
    let!(:complexity) { create(:complexity) }

    context "when authenticated with correct role" do
      before do
        put endpoint, headers: request_headers
      end

      it "inactivates the latest record" do
        expect(response).to have_http_status :ok
        complexity = Complexity.find_by!(offender_no: offender_no)
        expect(response_json)
          .to eq json_object(offenderNo: offender_no,
                             level: complexity.level,
                             sourceSystem: complexity.source_system,
                             createdTimeStamp: complexity.created_at,
                             active: complexity.active)
        expect(complexity.active).to eq(false)
      end
    end

    context "without role ROLE_UPDATE_COMPLEXITY_OF_NEED" do
      before do
        stub_access_token scopes: %w[read write], roles: %w[ROLE_COMPLEXITY_OF_NEED]
        put endpoint, headers: request_headers
      end

      include_examples "HTTP 403 Forbidden",
                       "You need the role 'ROLE_UPDATE_COMPLEXITY_OF_NEED' to use this endpoint"
    end

    context "when the client is unauthenticated" do
      before do
        put endpoint # don't include an Authorization header
      end

      include_examples "HTTP 401 Unauthorized"
    end

    context "when the client's token has expired" do
      before do
        # Travel into the future to expire the access token
        Timecop.travel(Time.zone.today + 1.year) do
          put endpoint, headers: request_headers
        end
      end

      include_examples "HTTP 401 Unauthorized"
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
