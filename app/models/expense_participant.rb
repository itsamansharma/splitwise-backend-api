class ExpenseParticipant < ApplicationRecord
  belongs_to :expense
  belongs_to :user

  validates :amount_owed, numericality: { greater_than_or_equal_to: 0 }
end
