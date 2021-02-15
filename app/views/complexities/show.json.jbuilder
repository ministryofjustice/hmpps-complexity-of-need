# frozen_string_literal: true

json.offenderNo @complexity.offender_no
json.extract! @complexity, :level
json.createdTimeStamp @complexity.created_at
json.sourceUser @complexity.user_id if @complexity.user_id
json.sourceSystem @complexity.source_system
