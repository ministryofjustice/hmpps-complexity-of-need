# frozen_string_literal: true

class AddActiveFlag < ActiveRecord::Migration[6.1]
  def change
    add_column :complexities, :active, :boolean, default: true
  end
end
