# frozen_string_literal: true

shared_examples "HTTP 403 Forbidden" do |error_message|
  it "returns HTTP 403 Forbidden" do
    expect(response).to have_http_status :forbidden
  end

  it "includes validation errors in the response" do
    expect(response_json).to eq json_object(message: error_message)
  end
end

shared_examples "HTTP 401 Unauthorized" do
  it "returns HTTP 401 Unauthorized" do
    expect(response).to have_http_status :unauthorized
  end

  it "includes validation errors in the response" do
    expect(response_json).to eq json_object(message: "Missing or invalid access token")
  end
end

shared_examples "SAR HTTP 403 Forbidden" do |error_message|
  it "returns HTTP 403 Forbidden" do
    expect(response).to have_http_status :forbidden
  end

  it "includes validation errors in the response" do
    expect(response_json).to eq({ "developerMessage" => error_message, "errorCode" => 5, "status" => 403, "userMessage" => error_message })
  end
end

shared_examples "SAR HTTP 401 Unauthorized" do |error_message = "Missing or invalid access token"|
  it "returns HTTP 401 Unauthorized" do
    expect(response).to have_http_status :unauthorized
  end

  it "includes validation errors in the response" do
    expect(response_json).to eq({ "developerMessage" => error_message, "errorCode" => 1, "status" => 401, "userMessage" => error_message })
  end
end
