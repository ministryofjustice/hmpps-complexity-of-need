# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    "v1/swagger.yaml" => {
      basePath: "/v1",
      openapi: "3.0.1",
      info: {
        title: "Complexity of Need API",
        version: "v1",
        description: <<~DESC,
          A microservice which holds the Complexity of Need level associated with offenders

          ### Authentication

          This API is secured by OAuth 2 with tokens supplied by HMPPS Auth.

          Read permissions are granted to any authorised client. No particular role is required.

          Write permissions are granted to clients with the role `ROLE_COMPLEXITY_OF_NEED` and a `write` scope.

          ---

          Owned by the **Manage POM Cases** team

          - Slack: [#ask_moic_pvb](https://mojdt.slack.com/channels/ask_moic_pvb)
          - GitHub: [ministryofjustice/hmpps-complexity-of-need](https://github.com/ministryofjustice/hmpps-complexity-of-need)
        DESC
      },
      consumes: ["application/json"],
      produces: ["application/json"],
      components: {
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
            },
            required: %w[offenderNo level createdTimeStamp sourceSystem],
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
          url: "https://complexity-of-need-staging.hmpps.service.justice.gov.uk/v1",
          description: "Staging/dev environment",
        },
        {
          url: "https://complexity-of-need-preprod.hmpps.service.justice.gov.uk/v1",
          description: "Pre-production environment",
        },
        {
          url: "https://complexity-of-need.hmpps.service.justice.gov.uk/v1",
          description: "Production environment",
        },
      ],
    },
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :yaml
end
