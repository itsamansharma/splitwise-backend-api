class User < ApplicationRecord
  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :friendships
  has_many :friends, through: :friendships
  
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id'
  has_many :inverse_friends, through: :inverse_friendships, source: :user

  has_many :group_members
  has_many :groups, through: :group_members
  has_many :created_groups, class_name: 'Group', foreign_key: 'created_by_id'

  has_many :expenses_paid, class_name: 'Expense', foreign_key: 'paid_by_id'
  has_many :expenses_created, class_name: 'Expense', foreign_key: 'created_by_id'
  
  has_many :expense_participants
  has_many :participated_expenses, through: :expense_participants, source: :expense

  has_many :settlements_paid, class_name: 'Settlement', foreign_key: 'payer_id'
  has_many :settlements_received, class_name: 'Settlement', foreign_key: 'receiver_id'

  has_many :notifications_received, class_name: 'Notification', foreign_key: 'receiver_id', dependent: :destroy
  has_many :notifications_sent, class_name: 'Notification', foreign_key: 'sender_id', dependent: :destroy
end
