# frozen_string_literal: true

class SwaggerDocsController < ApplicationController
  def index
    render json: File.read(Rails.root.join("swagger/v1/swagger.json"))
  end
end
