# frozen_string_literal: true

require "swagger_helper"

# The DescribeClass cop has been disabled as it is insists that the describe
# block contain the name of the tested class.  However rswag is using this
# text as part of the API documentation generated from these tests.
# rubocop:disable RSpec/DescribeClass
# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/ScatteredSetup
describe "Complexity of Need API", swagger_doc: "v1/swagger.yaml" do
  let(:topic) { instance_double("topic", publish: nil) }
  # Authorization header needs to be defined for rswag
  let(:Authorization) { auth_header } # rubocop:disable RSpec/VariableName

  before do
    allow(ComplexityEventService).to receive(:sns_topic).and_return(topic)
  end

  path "/complexity-of-need/offender-no/{offender_no}" do
    parameter name: :offender_no, in: :path, type: :string,
              description: "NOMIS Offender Number", example: "A0000AA"

    let(:offender_no) { "G4273GI" }

    get "Retrieve the current Complexity of Need level for an offender" do
      tags "Single Offender"

      response "200", "Offender's current Complexity of Need level found" do
        before do
          create(:complexity, :with_user, offender_no: offender_no)
        end

        schema "$ref" => "#/components/schemas/ComplexityOfNeed"

        run_test!
      end

      response "401", "Invalid or missing access token" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Access token is missing scope `read`" do
        before do
          stub_access_token scopes: []
        end

        run_test!
      end

      response "404", "The Complexity of Need level for this offender is not known" do
        run_test!
      end
    end

    post "Update the Complexity of Need level for an offender" do
      tags "Single Offender"
      description "Clients calling this endpoint must have role: `ROLE_UPDATE_COMPLEXITY_OF_NEED`"

      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/NewComplexityOfNeed" }

      response "200", "Complexity of Need level set successfully" do
        schema "$ref" => "#/components/schemas/ComplexityOfNeed"

        let(:body) { { level: "medium" } }

        run_test!
      end

      response "400", "There were validation errors. Make sure you've given a valid level." do
        let(:body) { { level: "potato" } }

        run_test!
      end

      response "401", "Invalid or missing access token" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Access token is missing role `ROLE_COMPLEXITY_OF_NEED` or scope `write`" do
        before do
          stub_access_token scopes: %w[read], roles: %w[SOME_OTHER_ROLE]
        end

        run_test!
      end
    end
  end

  path "/complexity-of-need/multiple/offender-no" do
    post "Retrieve the current Complexity of Need levels for multiple offenders" do
      tags "Multiple Offenders"
      description <<~DESC
        This endpoint returns a JSON array containing the current Complexity of Need entry for multiple offenders.

        The response array:
          - will exclude offenders whose Complexity of Need level is not known (i.e. these would result in a `404 Not Found` error on the single `GET` endpoint)
          - will exclude offenders without a current active level
          - is not sorted in the same order as the request body
          - is not paginated
      DESC

      parameter name: :body, in: :body, schema: {
        type: :array,
        items: { "$ref" => "#/components/schemas/OffenderNo" },
        description: "A JSON array of NOMIS Offender Numbers",
        example: %w[A0000AA B0000BB C0000CC],
      }

      response "200", "OK" do
        schema type: :array, items: { "$ref" => "#/components/schemas/ComplexityOfNeed" }

        let(:body) { %w[G4273GI A1111AA] }

        run_test!
      end

      response "400", "The request body was invalid. Make sure you've provided a JSON array of NOMIS Offender Numbers." do
        run_test!
      end

      response "401", "Invalid or missing access token" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Access token is missing scope `read`" do
        before do
          stub_access_token scopes: []
        end

        run_test!
      end
    end
  end

  path "/complexity-of-need/offender-no/{offender_no}/history" do
    parameter name: :offender_no, in: :path, type: :string,
              description: "NOMIS Offender Number", example: "A0000AA"

    let(:offender_no) { "G4273GI" }

    get "Retrieve full history of Complexity of Needs for an offender" do
      tags "Single Offender"
      description "Results are sorted chronologically (newest first, oldest last)"

      response "200", "Offender's Complexity of Need history found" do
        before do
          create(:complexity, :with_user, offender_no: offender_no, created_at: 1.month.ago, updated_at: 1.month.ago)
          create(:complexity, :with_user, offender_no: offender_no)
        end

        schema type: :array, items: { "$ref" => "#/components/schemas/ComplexityOfNeed" }

        run_test!
      end

      response "401", "Invalid or missing access token" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Access token is missing scope `read`" do
        before do
          stub_access_token scopes: []
        end

        run_test!
      end

      response "404", "The Complexity of Need level for this offender is not known" do
        run_test!
      end
    end
  end

  path "/complexity-of-need/offender-no/{offender_no}/inactivate" do
    parameter name: :offender_no, in: :path, type: :string,
              description: "NOMIS Offender Number", example: "A0000AA"

    let(:offender_no) { "G4273GI" }

    put "Inactivate the Complexity of Need level for an offender" do
      tags "Single Offender"
      description "Clients calling this endpoint must have role: `ROLE_UPDATE_COMPLEXITY_OF_NEED`"

      response "200", "Complexity of Need level inactivated successfully" do
        before do
          create(:complexity, :with_user, offender_no: offender_no)
        end

        schema "$ref" => "#/components/schemas/ComplexityOfNeed"

        run_test!
      end

      response "401", "Invalid or missing access token" do
        let(:Authorization) { nil } # rubocop:disable RSpec/VariableName

        run_test!
      end

      response "403", "Access token is missing role `ROLE_COMPLEXITY_OF_NEED` or scope `write`" do
        before do
          stub_access_token scopes: %w[read], roles: %w[SOME_OTHER_ROLE]
        end

        run_test!
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/DescribeClass
# rubocop:enable RSpec/ScatteredSetup
