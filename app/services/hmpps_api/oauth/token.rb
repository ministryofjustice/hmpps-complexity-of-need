# frozen_string_literal: true

require "base64"

module HmppsApi
  module Oauth
    class Token
      attr_reader :access_token

      def initialize(access_token)
        payload = JWT.decode(access_token, nil,
                             true, # Verify the signature of this token
                             algorithms: "RS256",
                             iss: "#{Rails.configuration.nomis_oauth_host}/auth/issuer",
                             verify_iss: true,
                             verify_aud: false) do |header|
          jwks_hash[header["kid"]]
        end
        #  method returns a 2-element array - so pick the first one
        # second one is technical info about key e.g. algorithm etc
        @payload = payload.first
        @access_token = access_token
      end

      def expired?
        @payload.fetch("exp") < Time.zone.now.to_i
      end

      def valid_token_with_scope?(scope)
        @payload.fetch("scope", []).include?(scope) && !expired?
      end

      def self.from_json(payload)
        Token.new(payload.fetch("access_token"))
      end

    private

      def jwks_hash
        # a combo of https://auth0.com/docs/quickstart/backend/rails/01-authorization?_ga=2.125705866.1258815838.1614860254-689132663.1593072635#configure-auth0-apis
        # and https://gist.github.com/trojkac/a78d5af6c62cc743dad6fbd7e337701b (as we don't have an x5c certificate)
        Hash[
          jwks_keys
            .map do |k|
            e = OpenSSL::BN.new(Base64.urlsafe_decode64(k.fetch("e")), 2)
            n = OpenSSL::BN.new(Base64.urlsafe_decode64(k.fetch("n")), 2)
            [
              k["kid"],
              OpenSSL::PKey::RSA.new.set_key(n, e, nil).public_key,
            ]
          end
        ]
      end

      def jwks_keys
        # Cache calls to this resource – it doesn't change frequently
        Rails.cache.fetch("hmpps_auth_jwks_keys", expires_in: 24.hours) do
          client = Faraday.new(Rails.configuration.nomis_oauth_host) do |conn|
            # Raise errors for bad HTTP responses
            conn.response :raise_error
          end

          response = client.get "/auth/.well-known/jwks.json"
          JSON.parse(response.body).fetch("keys")
        end
      end
    end
  end
end
