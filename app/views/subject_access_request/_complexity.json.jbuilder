# frozen_string_literal: true

json.extract! complexity, :level
json.createdTimeStamp complexity.created_at
json.updatedTimeStamp complexity.updated_at
json.extract! complexity, :notes if complexity.notes
json.extract! complexity, :active
