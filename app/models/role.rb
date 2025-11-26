class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: true
  validates :name, format: { with: /\A[a-z_][a-z0-9_]*\z/, message: "must be lowercase letters, numbers, and underscores only" }
end
