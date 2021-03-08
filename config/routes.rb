# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "/health" => "health#index"

  defaults format: :json do
    get "/complexity-of-need/offender-no/:offender_no" => "complexities#show"
    post "/complexity-of-need/offender-no/:offender_no" => "complexities#create"
    post "/complexity-of-need/multiple/offender-no" => "complexities#multiple"
  end
end
