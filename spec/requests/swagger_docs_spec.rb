require "rails_helper"

describe "Swagger Documentation surfaced for SRE discoverability" do
  describe "GET /swagger-ui.html" do
    it "redirects to the Swagger UI" do
      get "/swagger-ui.html"

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/api-docs/index.html")
    end
  end

  describe "GET /v3/api-docs" do
    it "renders the swagger.json file" do
      get "/v3/api-docs"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(File.read(Rails.root.join("swagger/v1/swagger.json")))
    end
  end
end
