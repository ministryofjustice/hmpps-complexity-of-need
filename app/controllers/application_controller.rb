# frozen_string_literal: true

class ApplicationController < ActionController::API
  READ_ROLE = "ROLE_COMPLEXITY_OF_NEED"
  WRITE_ROLE = "ROLE_UPDATE_COMPLEXITY_OF_NEED"
  SAR_ROLE = "ROLE_SAR_DATA_ACCESS"
  ADMIN_ROLE = "ROLE_CNL_ADMIN"

  rescue_from JWT::DecodeError, with: :render_bad_token

private

  def authorise_read!
    authorise_for!(READ_ROLE)
  end

  def authorise_write!
    authorise_for!(WRITE_ROLE)
  end

  def authorise_sar!
    authorise_for!(SAR_ROLE)
  end

  # ignore scopes - they don't make sense as they are client-wide not role-wide
  def authorise_for!(role)
    if token.nil?
      render_bad_token
    elsif !token.has_role?(role) && !token.has_role?(ADMIN_ROLE)
      render_forbidden "You need the role '#{role}' to use this endpoint"
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
    render json: { message: }, status: :forbidden
  end
end
