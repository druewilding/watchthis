class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  has_many :lists, dependent: :destroy
  has_many :sent_shares, class_name: "Share", foreign_key: :from_user_id, dependent: :destroy
  has_many :received_shares, class_name: "Share", foreign_key: :to_user_id, dependent: :destroy
  has_many :media_added, class_name: "Media", foreign_key: :added_by_id, dependent: :nullify
  has_many :initiated_friendships, class_name: "Friendship", foreign_key: :user_id, dependent: :destroy
  has_many :received_friendships, class_name: "Friendship", foreign_key: :friend_id, dependent: :destroy

  def inbox
    lists.find_by(is_default: true)
  end

  def friends
    friend_ids = Friendship.accepted.involving(self).map { |f| f.user_id == id ? f.friend_id : f.user_id }
    User.where(id: friend_ids)
  end

  def incoming_friend_requests
    Friendship.pending.where(friend: self).includes(:user)
  end

  def outgoing_friend_requests
    Friendship.pending.where(user: self).includes(:friend)
  end

  def name_or_email
    display_name.presence || email
  end
end
