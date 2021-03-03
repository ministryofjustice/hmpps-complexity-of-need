# frozen_string_literal: true

class ApplicationController < ActionController::API
  before_action :authenticate!

private

  def authenticate!
    access_token = parse_access_token(request.headers["AUTHORIZATION"])

    token = HmppsApi::Oauth::Token.new(access_token)
    unless token.valid_token_with_scope?("read")
      render_unauthorized("Valid authorisation token required")
    end
  end

  def parse_access_token(auth_header)
    return nil if auth_header.nil?
    return nil unless auth_header.starts_with?("Bearer")

    auth_header.split.last
  end

  def render_unauthorized(msg)
    render json: { status: "error", message: msg }, status: :unauthorized
  end
end
