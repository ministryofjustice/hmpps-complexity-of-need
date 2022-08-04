# frozen_string_literal: true

class ComplexityEventService
  class << self
    def send_complexity(complexity)
      sns_topic.publish(
        message: {
          offenderNo: complexity.offender_no,
          level: complexity.level,
          active: complexity.active
        }.to_json,
        message_attributes: {
          eventType: {
            string_value: "complexity-of-need.level.changed",
            data_type: "String",
          },
          version: {
            string_value: 1.to_s,
            data_type: "Number",
          },
          occurredAt: {
            string_value: complexity.created_at.to_s,
            data_type: "String",
          },
          detailURL: {
            string_value: Rails.application.routes.url_helpers.complexity_of_need_single_url(complexity.offender_no),
            data_type: "String",
          },
        },
      )
    end

  private

    # storing the topic like this will make it used across threads. Hopefully it's thread-safe
    def sns_topic
      @sns_topic ||= Aws::SNS::Resource.new(region: "eu-west-2")
                   .topic(ENV.fetch("DOMAIN_EVENTS_TOPIC_ARN"))
    end
  end
end
