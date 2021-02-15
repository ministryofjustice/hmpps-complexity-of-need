# frozen_string_literal: true

class ComplexitiesController < ApplicationController
  respond_to :json
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def show
    @complexity = Complexity.find_by!(offender_no: params[:offender_no])
  end

private

  def not_found
    render json: { error: "Not found" }.to_json, status: :not_found
  end
end
