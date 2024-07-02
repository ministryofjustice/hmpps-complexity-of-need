# frozen_string_literal: true

module AuthHelper
  def auth_header
    oauth_client = HmppsApi::Oauth::Client.new(Rails.configuration.nomis_oauth_host)
    route = "/auth/oauth/token?grant_type=client_credentials"

    # When running tests in CI, we mock auth calls
    # Otherwise, return a valid Authorization HTTP header with a real access token
    # This allows us to test the HMPPS Auth integration
    if ENV["MOCK_AUTH"].present?
      allow(oauth_client).to receive(:post).with(route).and_return({ "access_token" => "dummy-access-token" })
    end

    response = oauth_client.post(route)
    access_token = response.fetch("access_token")
    "Bearer #{access_token}"
  end

  # Mock the client's access token with the specified roles
  def stub_access_token(roles: [])
    token = instance_double(HmppsApi::Oauth::Token, access_token: "dummy-access-token")
    allow(token).to receive(:has_role?) { |role| roles.include?(role) }
    allow(token).to receive(:client_id) { Rails.configuration.nomis_oauth_client_id }
    allow(HmppsApi::Oauth::Token).to receive(:new).and_return(token)
  end

  def stub_expired_access_token
    if ENV["MOCK_AUTH"].present?
      allow(HmppsApi::Oauth::Token).to receive(:new).and_raise(JWT::ExpiredSignature)
    else
      allow(HmppsApi::Oauth::Token).to receive(:new).and_call_original
    end
  end
end
