# frozen_string_literal: true

module AuthHelper
  # Return a valid Authorization HTTP header with a real access token
  # This allows us to test the HMPPS Auth integration
  def auth_header
    oauth_client = HmppsApi::Oauth::Client.new(Rails.configuration.nomis_oauth_host)
    route = "/auth/oauth/token?grant_type=client_credentials"
    response = oauth_client.post(route)

    token = HmppsApi::Oauth::Token.from_json(response)

    "Bearer #{token.access_token}"
  end

  # Mock the client's access token with the specified scopes and roles
  def stub_access_token(scopes: [], roles: [])
    token = instance_double(HmppsApi::Oauth::Token, access_token: "dummy-access-token")
    allow(token).to receive(:has_scope?) { |scope| scopes.include?(scope) }
    allow(token).to receive(:has_role?) { |role| roles.include?(role) }
    allow(HmppsApi::Oauth::Token).to receive(:new).and_return(token)
  end
end
