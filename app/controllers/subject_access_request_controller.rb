# frozen_string_literal: true

class SubjectAccessRequestController < ApplicationController
  respond_to :json
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  before_action :authorise_sar!

  def show
    return render_error("Cannot supply both CRN and PRN", 2, 400) if params[:prn].present? && params[:crn].present?
    return render_error("CRN parameter not allowed", 3, 209) if params[:crn].present?
    return render_error("Invalid date format", 4, 210) unless parse_dates

    query = Complexity.where(offender_no: params[:prn])
    query = query.where(created_at: @from_date.beginning_of_day..@to_date.end_of_day) if @from_date && @to_date

    @complexities = query.order(:created_at)
    return not_found if @complexities.blank?

    @complexities
  end

private

  def parse_dates
    if params[:fromDate].blank? || params[:toDate].blank?
      @from_date = nil
      @to_date = nil
    else
      @from_date = Date.parse(params[:fromDate])
      @to_date = Date.parse(params[:toDate])
    end

    true
  rescue Date::Error
    false
  end

  def not_found
    head :no_content
  end

  def render_bad_token
    render_error("Missing or invalid access token", 1, 401)
  end

  def render_forbidden(message)
    render_error(message, 5, 403)
  end

  def render_error(msg, error_code, status)
    render json: {
      developerMessage: msg,
      errorCode: error_code,
      status:,
      userMessage: msg,
    }, status:
  end
end
