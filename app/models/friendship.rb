class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :status, inclusion: {in: %w[pending accepted]}
  validate :not_already_connected, on: :create

  scope :accepted, -> { where(status: "accepted") }
  scope :pending, -> { where(status: "pending") }
  scope :involving, ->(user) { where(user: user).or(where(friend: user)) }

  def self.between(user_a, user_b)
    where(user: user_a, friend: user_b).or(where(user: user_b, friend: user_a)).first
  end

  private

  def not_already_connected
    return unless user && friend
    if Friendship.between(user, friend)
      errors.add(:base, "A connection already exists with this user")
    end
  end
end
