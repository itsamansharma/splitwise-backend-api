class Expense < ApplicationRecord
  belongs_to :paid_by, class_name: 'User'
  belongs_to :group, optional: true
  belongs_to :created_by, class_name: 'User'
  
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user

  validates :title, presence: true
  validates :amount, numericality: { greater_than: 0 }
end
