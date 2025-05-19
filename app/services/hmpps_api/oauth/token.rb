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
                             verify_expiration: true, # Raises error JWT::ExpiredSignature if the token has expired
                             verify_aud: false) do |header|
          jwks_hash[header["kid"]]
        end
        #  method returns a 2-element array - so pick the first one
        # second one is technical info about key e.g. algorithm etc
        @payload = payload.first
        @access_token = access_token
      end

      def client_id
        @payload.fetch("client_id")
      end

      def has_role?(role)
        @payload.fetch("authorities", []).include?(role)
      end

      def self.from_json(payload)
        Token.new(payload.fetch("access_token"))
      end

    private

      # :nocov:
      def jwks_hash
        # a combo of https://auth0.com/docs/quickstart/backend/rails/01-authorization?_ga=2.125705866.1258815838.1614860254-689132663.1593072635#configure-auth0-apis
        # and https://gist.github.com/trojkac/a78d5af6c62cc743dad6fbd7e337701b (as we don't have an x5c certificate)
        Hash[
          jwks_keys.map do |k|
            # https://gist.github.com/WilliamNHarvey/0e37f84a86e66f9acb7ac8c68b0f996b
            data_sequence = OpenSSL::ASN1::Sequence([
              OpenSSL::ASN1::Integer(base64_to_long(k.fetch("n"))),
              OpenSSL::ASN1::Integer(base64_to_long(k.fetch("e"))),
            ])
            asn1 = OpenSSL::ASN1::Sequence(data_sequence)
            key = OpenSSL::PKey::RSA.new(asn1.to_der)

            [
              k["kid"],
              key.public_key,
            ]
          end,
        ]
      end
      # :nocov:

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

      # :nocov:
      def base64_to_long(data)
        decoded_with_padding = Base64.urlsafe_decode64(data) + Base64.decode64("==")
        decoded_with_padding.to_s.unpack("C*").map { |byte|
          byte_to_hex(byte)
        }.join.to_i(16)
      end
      # :nocov:

      # :nocov:
      def byte_to_hex(int)
        int < 16 ? "0#{int.to_s(16)}" : int.to_s(16)
      end
      # :nocov:
    end
  end
end
