class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  validates :status, inclusion: { in: %w[pending accepted blocked] }
  validates :friend_id, uniqueness: { scope: :user_id, message: "is already a friend" }
end
