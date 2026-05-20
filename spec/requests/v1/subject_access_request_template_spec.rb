# frozen_string_literal: true

require "rails_helper"
require "shared_examples"

RSpec.describe "Subject access request template", type: :request do
  let(:endpoint) { "/subject-access-request/template" }
  let(:response_json) { JSON.parse(response.body) }
  let(:request_headers) { { "Authorization" => auth_header } }
  let(:template_path) { SubjectAccessRequestTemplateService.template_path }

  describe "GET /subject-access-request/template" do
    context "when the client has the ROLE_SAR_DATA_ACCESS role" do
      before do
        stub_access_token roles: %w[ROLE_SAR_DATA_ACCESS]
        get endpoint, headers: request_headers
      end

      it "returns status OK" do
        expect(response).to have_http_status :ok
      end

      it "returns the template body as plain text" do
        expect(response.media_type).to eq "text/plain"
        expect(response.body).to eq File.read(template_path, encoding: "UTF-8")
      end
    end

    context "when the client lacks the ROLE_SAR_DATA_ACCESS role" do
      before do
        stub_access_token roles: %w[ROLE_WHATEVER]
        get endpoint, headers: request_headers
      end

      include_examples "SAR HTTP 403 Forbidden", "You need the role 'ROLE_SAR_DATA_ACCESS' to use this endpoint"
    end

    context "when the client is unauthenticated" do
      before do
        get endpoint
      end

      include_examples "SAR HTTP 401 Unauthorized"
    end
  end
end
