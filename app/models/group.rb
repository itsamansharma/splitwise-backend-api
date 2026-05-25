class Group < ApplicationRecord
  belongs_to :created_by, class_name: 'User'
  has_many :group_members, dependent: :destroy
  has_many :members, through: :group_members, source: :user
  has_many :expenses, dependent: :destroy

  validates :name, presence: true
end
