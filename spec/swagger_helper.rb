# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.openapi_specs = {
    "v1/swagger.json" => {
      openapi: "3.0.1",
      info: {
        title: "Complexity of Need API",
        version: "v1",
        description: <<~DESC,
          A microservice which holds the Complexity of Need level associated with offenders

          ### Authentication

          This API is secured by OAuth 2 with tokens supplied by HMPPS Auth.

          Read permissions are granted to clients with the role `ROLE_COMPLEXITY_OF_NEED`

          Write permissions are granted to clients with the role `ROLE_UPDATE_COMPLEXITY_OF_NEED`.

          To use the SAR API, clients will need the role `ROLE_SAR_DATA_ACCESS`.

          ---

          Owned by the **Manage POM Cases** team

          - Slack: [#manage-pom-cases](https://mojdt.slack.com/channels/manage-pom-cases)
          - GitHub: [ministryofjustice/hmpps-complexity-of-need](https://github.com/ministryofjustice/hmpps-complexity-of-need)
        DESC
      },
      # Defaults for all endpoints:
      consumes: ["application/json"], # Only accept JSON payloads
      produces: ["application/json"], # Only return JSON responses
      security: [HmppsAuth: %w[read]], # Require a valid HMPPS Auth token with "read" scope
      components: {
        securitySchemes: {
          Bearer: {
            type: "apiKey",
            description: "A bearer token obtained from HMPPS SSO",
            name: "Authorization",
            in: "header",
          },
          HmppsAuth: {
            type: :oauth2,
            # HMPPS Auth uses the 'client credentials' oAuth 2 flow: https://swagger.io/docs/specification/authentication/oauth2/
            flows: {
              clientCredentials: {
                scopes: {
                  read: "Grants read access",
                  write: "Grants write access",
                },
              },
            },
          },
        },
        schemas: {
          Level: {
            type: :string,
            enum: Complexity::VALID_LEVELS,
            description: "Complexity of Need Level",
            example: Complexity::VALID_LEVELS.first,
          },
          OffenderNo: {
            type: :string,
            description: "NOMIS Offender Number",
            example: "A0000AA",
          },
          ComplexityOfNeed: {
            type: :object,
            properties: {
              offenderNo: { "$ref" => "#/components/schemas/OffenderNo" },
              level: { "$ref" => "#/components/schemas/Level" },
              sourceUser: {
                type: :string,
                description: "The NOMIS username that supplied this Complexity of Need entry",
                example: "JSMITH_GEN",
              },
              sourceSystem: {
                type: :string,
                description: "The OAuth Client ID of the system that created this entry",
                example: "hmpps-api-client-id",
              },
              notes: {
                type: :string,
                description: "Free-text notes for this entry",
              },
              createdTimeStamp: {
                type: :string,
                format: :date_time,
                description: "The date & time this entry was created (in RFC 3339 format)",
                example: "2021-03-02T17:18:46.457Z",
              },
              active: {
                type: :boolean,
                description: "Whether it is active or not",
              },
            },
            required: %w[offenderNo level createdTimeStamp sourceSystem active],
            additionalProperties: false,
          },
          NewComplexityOfNeed: {
            type: :object,
            properties: {
              level: { "$ref" => "#/components/schemas/Level" },
              sourceUser: {
                type: :string,
                description: "The NOMIS username that supplied this Complexity of Need entry",
                example: "JSMITH_GEN",
              },
              notes: {
                type: :string,
                description: "Free-text notes for this entry",
              },
            },
            required: %w[level],
            additionalProperties: false,
          },
          SarError: {
            required: %w[developerMessage errorCode status userMessage],
            type: :object,
            properties: {
              developerMessage: { type: :string },
              errorCode: { type: :integer },
              status: { type: :integer },
              userMessage: { type: :string },
            },
          },
          SarOffenderData: {
            required: %w[content],
            type: :object,
            properties: {
              content: {
                type: :array,
                items: { "$ref" => "#/components/schemas/ComplexityOfNeed" },
              },
            },
          },
        },
      },
      tags: [
        {
          name: "Single Offender",
          description: "Access Complexity of Need for a single offender",
        },
        {
          name: "Multiple Offenders",
          description: "Access Complexity of Need for multiple offenders at once",
        },
      ],
      paths: {},
      servers: [
        {
          url: "https://complexity-of-need-staging.hmpps.service.justice.gov.uk",
          description: "Staging/dev environment",
        },
        {
          url: "https://complexity-of-need-preprod.hmpps.service.justice.gov.uk",
          description: "Pre-production environment",
        },
        {
          url: "https://complexity-of-need.hmpps.service.justice.gov.uk",
          description: "Production environment",
        },
      ],
    },
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :json
end
