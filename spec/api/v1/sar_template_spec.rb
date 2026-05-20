# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
# rubocop:disable RSpec/VariableName
# rubocop:disable RSpec/ScatteredSetup

require "swagger_helper"

describe "Complexity of Need API", swagger_doc: "v1/swagger.json" do
  let(:template_path) { SubjectAccessRequestTemplateService.template_path }

  path "/subject-access-request/template" do
    get "Retrieves the SAR mustache template for this service" do
      security [{ Bearer: [] }]

      tags "Subject Access Request"
      description "* The role ROLE_SAR_DATA_ACCESS is required\n* Returns the plain-text mustache template configured for the service"

      produces "text/plain"

      response "401", "Request is not authorised" do
        example "application/json", :error_example, {
          developerMessage: "Missing or invalid access token",
          errorCode: 1,
          status: 401,
          userMessage: "Missing or invalid access token",
        }

        let(:Authorization) { nil }

        run_test!
      end

      response "403", "Invalid token role" do
        example "application/json", :error_example, {
          developerMessage: "You need the role 'ROLE_SAR_DATA_ACCESS' to use this endpoint",
          errorCode: 5,
          status: 403,
          userMessage: "You need the role 'ROLE_SAR_DATA_ACCESS' to use this endpoint",
        }

        let(:Authorization) { auth_header }

        before do
          stub_access_token roles: %w[ROLE_WHATEVER]
        end

        run_test!
      end

      response "200", "Template returned" do
        schema type: :string

        let(:Authorization) { auth_header }

        before do
          stub_access_token roles: %w[ROLE_SAR_DATA_ACCESS]
        end

        run_test! do |response|
          expect(response.media_type).to eq("text/plain")
          expect(response.body).to eq(File.read(template_path, encoding: "UTF-8"))
        end
      end
    end
  end
end

# rubocop:enable RSpec/ScatteredSetup
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/DescribeClass
