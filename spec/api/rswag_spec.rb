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
    get "Retrieves the current complexity" do
      produces "application/json"
      parameter name: :offender_no, in: :path, type: :string, description: "NOMIS Offender Number"

      response "200", "complexity found" do
        before do
          create(:complexity, :with_user, offender_no: offender_no)
        end

        schema "$ref" => "#/components/schemas/ComplexityOfNeed"

        let(:offender_no) { "G4273GI" }

        run_test!
      end

      response "404", "record not found" do
        let(:offender_no) { "A1111AA" }

        run_test!
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/DescribeClass
