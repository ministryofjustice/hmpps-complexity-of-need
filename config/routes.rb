# frozen_string_literal: true

# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "/ping" => "health#index"
  get "/health" => "health#index"

  # Default the request format to JSON – avoids need for .json file extension on paths
  defaults format: :json do
    # Prefix endpoints with /v1
    scope path: "/v1" do
      get "/complexity-of-need/offender-no/:offender_no" => "complexities#show", as: :complexity_of_need_single
      post "/complexity-of-need/offender-no/:offender_no" => "complexities#create"
      post "/complexity-of-need/multiple/offender-no" => "complexities#multiple"
      get "/complexity-of-need/offender-no/:offender_no/history" => "complexities#history"
      put "/complexity-of-need/offender-no/:offender_no/inactivate" => "complexities#inactivate"
    end
  end
end
