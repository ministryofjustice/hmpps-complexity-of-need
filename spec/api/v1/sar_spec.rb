# frozen_string_literal: true

# rubocop:disable Style/StringLiterals
# rubocop:disable RSpec/VariableName
# rubocop:disable RSpec/DescribeClass
# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/ScatteredSetup

require 'swagger_helper'

describe 'Complexity of Need API', swagger_doc: 'v1/swagger.json' do
  let(:topic) { instance_double(Aws::SNS::Topic, publish: nil) }

  before do
    allow(ComplexityEventService).to receive(:sns_topic).and_return(topic)
  end

  path '/subject-access-request' do
    get 'Retrieves all held info for offender' do
      security [Bearer: []]

      tags 'Subject Access Request'
      description "* NOMIS Prison Number (PRN) must be provided as part of the request.
* The role ROLE_SAR_DATA_ACCESS is required
* If the product uses the identifier type transmitted in the request, it can respond with its data and HTTP code 200
* If the product uses the identifier type transmitted in the request but has no data to respond with, it should respond with HTTP code 204
* If the product does not use the identifier type transmitted in the request, it should respond with HTTP code 209"

      produces 'application/json'
      consumes 'application/json'

      parameter name: :prn,
                in: :query,
                schema: { '$ref' => '#/components/schemas/OffenderNo' },
                description: 'NOMIS Prison Reference Number'
      parameter name: :crn,
                in: :query,
                type: :string,
                description: 'nDelius Case Reference Number. **Do not use this parameter for this endpoint**'
      parameter name: :fromDate,
                in: :query,
                type: :string,
                description: 'Optional parameter denoting minimum date of event occurrence which should be returned in the response (if used, both dates must be provided)'
      parameter name: :toDate,
                in: :query,
                type: :string,
                description: 'Optional parameter denoting maximum date of event occurrence which should be returned in the response (if used, both dates must be provided)'

      describe 'when not authorised' do
        let(:Authorization) { nil }

        response '401', 'Request is not authorised' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: "Missing or invalid access token",
            errorCode: 401,
            status: 401,
            userMessage: "Missing or invalid access token",
          }

          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end
      end

      describe 'when forbidden due to role' do
        let(:Authorization) { auth_header }

        before do
          stub_access_token roles: %w[ROLE_WHATEVER]
        end

        response '403', 'Invalid token role' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: "You need the role 'ROLE_SAR_DATA_ACCESS' to use this endpoint",
            errorCode: 403,
            status: 403,
            userMessage: "You need the role 'ROLE_SAR_DATA_ACCESS' to use this endpoint",
          }

          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end
      end

      describe 'when authorised' do
        let(:Authorization) { auth_header }

        before do
          stub_access_token roles: %w[ROLE_SAR_DATA_ACCESS]
        end

        response '400', 'Both PRN and CRN parameter passed' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: 'Cannot supply both CRN and PRN',
            errorCode: 400,
            status: 400,
            userMessage: 'Cannot supply both CRN and PRN',
          }

          let(:crn) { '123456' }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end

        response '209', 'CRN parameter not allowed' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: 'CRN parameter not allowed',
            errorCode: 209,
            status: 209,
            userMessage: 'CRN parameter not allowed',
          }

          let(:crn) { '123456' }
          let(:prn) { nil }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end

        response '210', 'Invalid date format' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: 'Invalid date format',
            errorCode: 210,
            status: 210,
            userMessage: 'Invalid date format',
          }

          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { 'apples' }
          let(:toDate) { 'pears' }

          run_test!
        end

        response '204', 'Offender not found' do
          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end

        response '200', 'Offender found' do
          schema '$ref' => '#/components/schemas/SarOffenderData'

          let(:time1) { Time.zone.now - 3.days }
          let(:time2) { Time.zone.now - 2.days }
          let(:time3) { Time.zone.now - 1.day }

          let(:offender_no) { 'A000BC' }

          before do
            create(:complexity, offender_no:, created_at: time1, active: true)
            create(:complexity, offender_no:, created_at: time2, active: false)
            create(:complexity, offender_no:, created_at: time3, active: true)
          end

          context 'with no date range' do
            let(:crn) { nil }
            let(:prn) { 'A000BC' }
            let(:fromDate) { nil }
            let(:toDate) { nil }

            run_test!
          end

          context 'with date range' do
            let(:crn) { nil }
            let(:prn) { 'A000BC' }
            let(:fromDate) { (Time.zone.today - 1.day).to_s }
            let(:toDate) { (Time.zone.today + 1.day).to_s }

            run_test!
          end
        end
      end
    end
  end
end

# rubocop:enable RSpec/ScatteredSetup
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/DescribeClass
# rubocop:enable RSpec/VariableName
# rubocop:enable Style/StringLiterals
