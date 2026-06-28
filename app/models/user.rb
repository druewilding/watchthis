class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  has_many :lists, dependent: :destroy

  def inbox
    lists.find_by(is_default: true)
  end
end
