# frozen_string_literal: true

module Patches
  module ApplicationInsights
    module TrackRequest
      IGNORED_PATHS = %w[/info /health /health/ping].freeze

      def call(env)
        return @app.call(env) if ignored_path?(env)

        super
      end

    private

      def options_hash(request)
        super.merge(name: request_name(request))
      end

      def request_name(request)
        "#{request.request_method} #{route_template(request) || request.path}"
      end

      # Prefer a low-cardinality template like `/v1/complexity-of-need/offender-no/:offender_no`
      # over the raw path. Returns nil when no useful template is available.
      def route_template(request)
        route = request.env["action_dispatch.route"]
        template = route&.path&.spec&.to_s
        return if template.blank?

        normalized_template = template.delete_suffix("(.:format)")
        return if normalized_template == "/*path"

        normalized_template
      end

      def ignored_path?(env)
        IGNORED_PATHS.include?(Rack::Request.new(env).path)
      end
    end
  end
end
