# frozen_string_literal: true

class CreateComplexities < ActiveRecord::Migration[6.1]
  def change
    create_table :complexities, id: :uuid do |t|
      t.string :offender_no, null: false
      t.string :level, null: false
      t.integer :user_id
      t.string :source_system, null: false

      t.timestamps
    end
  end
end
