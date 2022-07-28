# frozen_string_literal: true

module AuthHelper
  # Return a valid Authorization HTTP header with a real access token
  # This allows us to test the HMPPS Auth integration
  def auth_header
    oauth_client = HmppsApi::Oauth::Client.new(Rails.configuration.nomis_oauth_host)
    route = "/auth/oauth/token?grant_type=client_credentials"
    response = oauth_client.post(route)
    access_token = response.fetch("access_token")
    "Bearer #{access_token}"
  end

  # Mock the client's access token with the specified scopes and roles
  def stub_access_token(scopes: [], roles: [], expired_token: false, source_system: Rails.configuration.nomis_oauth_client_id)
    if expired_token
      token = nil
    else
      token = instance_double(HmppsApi::Oauth::Token, access_token: "dummy-access-token")
      allow(token).to receive(:has_scope?) { |scope| scopes.include?(scope) }
      allow(token).to receive(:has_role?) { |role| roles.include?(role) }
      allow(token).to receive(:client_id).and_return(source_system)
    end

    allow(HmppsApi::Oauth::Token).to receive(:new).and_return(token)
  end
end
