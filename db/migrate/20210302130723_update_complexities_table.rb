# frozen_string_literal: true

class UpdateComplexitiesTable < ActiveRecord::Migration[6.1]
  def change
    remove_column :complexities, :user_id, :integer

    change_table :complexities, bulk: true do |t|
      t.string :source_user
      t.string :notes
      t.index :offender_no
    end
  end
end
