# frozen_string_literal: true

require "rails_helper"
require "shared_examples"

RSpec.describe "Subject access request", type: :request do
  let(:response_json) { JSON.parse(response.body) }
  let(:topic) { instance_double("topic", publish: nil) }

  let(:request_headers) do
    # Include an Authorization header to make the request valid
    { "Authorization" => auth_header }
  end

  before do
    allow(ComplexityEventService).to receive(:sns_topic).and_return(topic)
  end

  describe "GET /v1/subject-access-request" do
    let(:endpoint) { "/v1/subject-access-request" }
    let(:get_body) { {} }

    let(:time1) { Time.zone.now - 3.days }
    let(:time2) { Time.zone.now - 2.days }
    let(:time3) { Time.zone.now - 1.day }

    let(:offender_no) { "A000BC" }
    let!(:complexity1) { create(:complexity, offender_no: offender_no, created_at: time1, active: true) }
    let!(:complexity2) { create(:complexity, offender_no: offender_no, created_at: time2, active: false) }
    let!(:complexity3) { create(:complexity, offender_no: offender_no, created_at: time3, active: true) }

    before do
      get endpoint, headers: request_headers, params: get_body
    end

    shared_examples "returns expected complexities" do
      it "returns expected complexity records whether active or not" do # rubocop:disable RSpec/ExampleLength
        expect(response_json).to eq json_object({
          content: expected_complexities.map do |c|
            {
              offenderNo: c.offender_no,
              level: c.level,
              sourceSystem: c.source_system,
              sourceUser: c.source_user,
              notes: c.notes,
              createdTimeStamp: c.created_at,
              active: c.active,
            }
          end,
        })
      end
    end

    shared_examples "returns an error response" do
      it "returns an error response" do
        expect(response_json.keys).to eq %w[developerMessage errorCode status userMessage]
      end
    end

    context "when passed both a prn and crn as query parameters" do
      let(:get_body) do
        {
          prn: "bobbins",
          crn: "bobbins",
        }
      end

      it "returns status 500" do
        expect(response).to have_http_status "500"
      end

      it_behaves_like "returns an error response"
    end

    context "when passed a crn" do
      let(:get_body) do
        { crn: "bobbins" }
      end

      it "returns status 209" do
        expect(response).to have_http_status "209"
      end

      it_behaves_like "returns an error response"
    end

    context "with no matching complexities" do
      let(:get_body) do
        { prn: "bobbins" }
      end

      it "returns 204" do
        expect(response).to have_http_status "204"
      end

      it "returns blank body" do
        expect(response.body).to eq ""
      end
    end

    context "with no to or from dates" do
      let(:expected_complexities) { [complexity1, complexity2, complexity3] }

      let(:get_body) do
        { prn: offender_no }
      end

      it "returns status OK" do
        expect(response).to have_http_status :ok
      end

      it_behaves_like "returns expected complexities"
    end

    context "with to and from dates" do
      let(:expected_complexities) { [complexity1, complexity2] }

      let(:get_body) do
        {
          prn: offender_no,
          fromDate: time1.to_date,
          toDate: time2.to_date,
        }
      end

      it "returns status OK" do
        expect(response).to have_http_status :ok
      end

      it_behaves_like "returns expected complexities"
    end

    # TODO: This endpoint should be protected by role: ROLE_SAR-DATA-ACCESS and ROLE_???.
    # Need some role that we already have access to as MPC

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
end
