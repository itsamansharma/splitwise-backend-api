class AddGroupIdToSettlements < ActiveRecord::Migration[8.1]
  def change
    add_reference :settlements, :group, null: true, foreign_key: true
  end
end
