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
      openapi: "3.0.1",
      info: {
        title: "API V1",
        version: "v1",
      },
      components: {
        schemas: {
          Level: {
            type: :string,
            enum: Complexity::VALID_LEVELS,
            description: "Complexity of Need Level",
            example: Complexity::VALID_LEVELS.first,
          },
          ComplexityOfNeed: {
            type: :object,
            properties: {
              offenderNo: {
                type: :string,
                description: "NOMIS Offender Number",
                example: "A0000AA",
              },
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
      paths: {},
      servers: [
        {
          url: "https://{defaultHost}",
          variables: {
            defaultHost: {
              default: "www.example.com",
            },
          },
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
