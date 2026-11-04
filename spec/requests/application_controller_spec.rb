require "rails_helper"
require "rack/mock"

RSpec.describe ApplicationController, type: :request do
  subject(:log_options) do
    Rails.application.config.lograge.custom_options.call(double(payload: payloads.last))
  end

  let(:controller_class) do
    Class.new(described_class) do
      def index
        raise "request failed" if params[:fail]

        head :ok
      end
    end
  end

  let(:payloads) { [] }
  let(:middleware) { ActionDispatch::RequestId.new(controller_class.action(:index), header: "X-Request-Id") }
  let(:env) { Rack::MockRequest.env_for("/example", "HTTP_X_REQUEST_ID" => "request-id") }
  let(:subscriber) do
    ActiveSupport::Notifications.subscribe("process_action.action_controller") { |event| payloads << event.payload }
  end

  before do
    subscriber
  end

  after do
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it "includes the Rails request ID in structured logs for successful requests" do
    middleware.call(env)

    expect(log_options).to eq(request_id: "request-id")
  end

  it "includes the Rails request ID and exception details for failed requests" do
    expect { middleware.call(env.merge("QUERY_STRING" => "fail=true")) }.to raise_error(RuntimeError, "request failed")

    expect(log_options).to include(
      request_id: "request-id",
      exception: ["RuntimeError", "request failed"],
      backtrace: an_instance_of(Array),
    )
  end
end
