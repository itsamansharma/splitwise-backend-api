class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.string :title
      t.text :description
      t.decimal :amount
      t.references :paid_by, null: false, foreign_key: { to_table: :users }
      t.references :group, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.date :date
      t.string :split_type

      t.timestamps
    end
  end
end
