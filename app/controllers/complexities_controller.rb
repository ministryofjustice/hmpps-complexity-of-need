# frozen_string_literal: true

class ComplexitiesController < ApplicationController
  respond_to :json
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :validation_error

  before_action :authorise_read!,  only: %i[show multiple history]
  before_action :authorise_write!, only: %i[create inactivate]

  # Read operations
  def show
    @complexity = Complexity.order(created_at: :desc).find_by!(offender_no: params[:offender_no])
    not_found unless @complexity.active?
  end

  def multiple
    return missing_offender_numbers unless params["_json"].is_a? Array

    offender_nos = params["_json"]
    @complexities = Complexity.latest_for_offenders(offender_nos)

    Rails.logger.info("ComplexitiesController.multiple: #{offender_nos.size} requested / #{@complexities.size} returned")
  end

  def history
    @complexities = Complexity.where(offender_no: params[:offender_no]).order(created_at: :desc)
    not_found if @complexities.blank?
  end

  # Write operations
  def create
    @complexity = Complexity.create!(create_params)
    render "show"
  end

  def inactivate
    @complexity = Complexity.order(created_at: :desc).find_by!(offender_no: params[:offender_no])
    @complexity.update!(active: false)
    render "show"
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
          .merge(source_system: token.client_id)
  end
end
