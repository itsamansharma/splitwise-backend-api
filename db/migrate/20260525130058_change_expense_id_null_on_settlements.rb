class ChangeExpenseIdNullOnSettlements < ActiveRecord::Migration[8.1]
  def change
    change_column_null :settlements, :expense_id, true
  end
end
