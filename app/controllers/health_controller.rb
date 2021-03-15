# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :authorise_read!

  def index
    render plain: "Everything is fine."
  end
end
