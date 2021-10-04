# frozen_string_literal: true

module HmppsApi
  module Oauth
    class Client
      def initialize(host)
        @host = host
        @connection = Faraday.new do |faraday|
          faraday.response :raise_error
        end
      end

      def post(route)
        request(:post, route)
      end

    private

      def request(method, route)
        response = @connection.send(method) do |req|
          url = URI.join(@host, route).to_s
          req.url(url)
          req.headers["Authorization"] = authorisation
        end

        JSON.parse(response.body)
      end

      def authorisation
        credentials = "#{Rails.configuration.nomis_oauth_client_id}:#{Rails.configuration.nomis_oauth_client_secret}"
        "Basic #{Base64.urlsafe_encode64(credentials)}"
      end
    end
  end
end
