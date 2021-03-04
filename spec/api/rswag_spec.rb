# frozen_string_literal: true

require "swagger_helper"

# The DescribeClass cop has been disabled as it is insists that the describe
# block contain the name of the tested class.  However rswag is using this
# text as part of the API documentation generated from these tests.
# rubocop:disable RSpec/DescribeClass
# rubocop:disable RSpec/EmptyExampleGroup
# Authorization 'method' needs to be defined for rswag
describe "Complexity API" do
  path "/complexity-of-need/offender-no/{offender_no}" do
    parameter name: :offender_no, in: :path, type: :string,
              description: "NOMIS Offender Number", example: "A0000AA"

    get "Retrieves the current complexity" do
      produces "application/json"

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

    post "Store a new Complexity of Need entry for the given NOMIS Offender Number" do
      description "Requires role: `CHANGE_COMPLEXITY`"
      consumes "application/json"
      produces "application/json"

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
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/DescribeClass
