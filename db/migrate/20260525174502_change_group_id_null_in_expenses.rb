class ChangeGroupIdNullInExpenses < ActiveRecord::Migration[8.1]
  def change
    change_column_null :expenses, :group_id, true
  end
end
