# frozen_string_literal: true

class ComplexitiesController < ApplicationController
  respond_to :json
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :validation_error

  def show
    @complexity = Complexity.order(created_at: :desc).find_by!(offender_no: params[:offender_no])
  end

  def create
    @complexity = Complexity.create!(create_params)
    render "show"
  end

  def multiple
    return missing_offender_numbers unless params["_json"].is_a? Array

    @complexities = Complexity.latest_for_offenders(params["_json"])
  end

private

  def not_found
    render json: { message: "No record found for that offender" }, status: :not_found
  end

  def validation_error(error)
    render json: { message: "Validation error", errors: error.record.errors }, status: :bad_request
  end

  def missing_offender_numbers
    render json: { message: "You must provide a JSON array of NOMIS Offender Numbers in the request body" }, status: :bad_request
  end

  def create_params
    params.permit(:offender_no, :level, :sourceUser, :notes)
          .transform_keys { |k| k == "sourceUser" ? "source_user" : k } # Convert "sourceUser" key to "source_user"
          .merge(source_system: "hardcoded-oauth-client-id") # TODO: use the HMPPS oAuth client ID here
  end
end
