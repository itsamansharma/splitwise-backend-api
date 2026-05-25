class Settlement < ApplicationRecord
  belongs_to :payer, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  belongs_to :expense, optional: true
  belongs_to :group, optional: true

  validates :amount, numericality: { greater_than: 0 }
end
