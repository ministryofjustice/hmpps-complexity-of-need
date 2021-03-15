# frozen_string_literal: true

class ApplicationController < ActionController::API
  # The HMPPS Auth role required for 'write' endpoints
  WRITE_ROLE = "ROLE_COMPLEXITY_OF_NEED"

  before_action :authorise_read!

  rescue_from JWT::DecodeError, with: :render_bad_token

private

  def authorise_read!
    if token.nil?
      render_bad_token
    elsif token.has_scope?("read") == false
      render_forbidden "You need the scope 'read' to use this endpoint"
    end
  end

  def authorise_write!
    if token.nil?
      render_bad_token
    elsif (token.has_scope?("write") && token.has_role?(WRITE_ROLE)) == false
      render_forbidden "You need the role '#{WRITE_ROLE}' with scope 'write' to use this endpoint"
    end
  end

  def token
    @token ||= begin
                 auth_header = request.headers["Authorization"]
                 if auth_header.present? && auth_header.starts_with?("Bearer")
                   access_token = auth_header.split.last
                   HmppsApi::Oauth::Token.new(access_token)
                 end
               end
  end

  def render_bad_token
    render json: { message: "Missing or invalid access token" }, status: :unauthorized
  end

  def render_forbidden(message)
    render json: { message: message }, status: :forbidden
  end
end
