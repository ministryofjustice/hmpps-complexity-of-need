# frozen_string_literal: true

require "swagger_helper"

# The DescribeClass cop has been disabled as it is insists that the describe
# block contain the name of the tested class.  However rswag is using this
# text as part of the API documentation generated from these tests.
# rubocop:disable RSpec/DescribeClass
# rubocop:disable RSpec/EmptyExampleGroup
# Authorization 'method' needs to be defined for rswag
describe "Complexity of Need API", swagger_doc: "v1/swagger.yaml" do
  path "/complexity-of-need/offender-no/{offender_no}" do
    parameter name: :offender_no, in: :path, type: :string,
              description: "NOMIS Offender Number", example: "A0000AA"

    get "Retrieve the current Complexity of Need level for an offender" do
      tags "Single Offender"

      response "200", "Offender's current Complexity of Need level found" do
        before do
          create(:complexity, :with_user, offender_no: offender_no)
        end

        schema "$ref" => "#/components/schemas/ComplexityOfNeed"

        let(:offender_no) { "G4273GI" }

        run_test!
      end

      response "404", "The Complexity of Need level for this offender is not known" do
        let(:offender_no) { "A1111AA" }

        run_test!
      end
    end

    post "Update the Complexity of Need level for an offender" do
      tags "Single Offender"
      description "Clients calling this endpoint must have role: `ROLE_COMPLEXITY_OF_NEED` with scope: `write`"

      parameter name: :body, in: :body, schema: { "$ref" => "#/components/schemas/NewComplexityOfNeed" }

      response "200", "Complexity of Need level set successfully" do
        schema "$ref" => "#/components/schemas/ComplexityOfNeed"

        let(:offender_no) { "G4273GI" }
        let(:body) { { level: "medium" } }

        run_test!
      end

      response "400", "There were validation errors. Make sure you've given a valid level." do
        let(:offender_no) { "G4273GI" }
        let(:body) { { level: "potato" } }

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
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/DescribeClass
