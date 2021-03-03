# frozen_string_literal: true

module AuthHelper
  def auth_header
    oauth_client = HmppsApi::Oauth::Client.new(Rails.configuration.nomis_oauth_host)
    route = "/auth/oauth/token?grant_type=client_credentials"
    response = oauth_client.post(route)

    token = HmppsApi::Oauth::Token.from_json(response)

    "Bearer #{token.access_token}"
  end
end
