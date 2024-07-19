# frozen_string_literal: true

class InfoController < ApplicationController
  BUILD_NAME = "hmpps-complexity-of-need"

  def index
    render json: {
      git: {
        branch: ENV["GIT_BRANCH"],
      },
      build: {
        artifact: BUILD_NAME,
        version: ENV["BUILD_NUMBER"],
        name: BUILD_NAME,
      },
      productId: ENV["PRODUCT_ID"],
    }
  end
end
