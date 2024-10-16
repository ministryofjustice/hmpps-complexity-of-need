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

      # Performs a basic GET request without processing the response. This is mostly
      # used for when we do not want a JSON response from an endpoint.
      # Currently used in the `health` endpoint.
      def raw_get(route)
        request(:get, route, parse: false)
      end

    private

      def request(method, route, parse: true)
        response = @connection.send(method) do |req|
          url = URI.join(@host, route).to_s
          req.url(url)
          req.headers["Authorization"] = authorisation
        end

        parse ? JSON.parse(response.body) : response.body
      end

      def authorisation
        credentials = "#{Rails.configuration.nomis_oauth_client_id}:#{Rails.configuration.nomis_oauth_client_secret}"
        "Basic #{Base64.urlsafe_encode64(credentials)}"
      end
    end
  end
end
