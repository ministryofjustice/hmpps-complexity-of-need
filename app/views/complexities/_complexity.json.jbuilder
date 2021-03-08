# frozen_string_literal: true

json.offenderNo complexity.offender_no
json.extract! complexity, :level
json.createdTimeStamp complexity.created_at
json.sourceUser complexity.source_user if complexity.source_user
json.sourceSystem complexity.source_system
json.extract! complexity, :notes if complexity.notes
