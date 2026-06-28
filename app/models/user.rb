class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  has_many :lists, dependent: :destroy
  has_many :sent_shares, class_name: "Share", foreign_key: :from_user_id, dependent: :destroy
  has_many :received_shares, class_name: "Share", foreign_key: :to_user_id, dependent: :destroy
  has_many :media_added, class_name: "Media", foreign_key: :added_by_id, dependent: :nullify

  def inbox
    lists.find_by(is_default: true)
  end
end
