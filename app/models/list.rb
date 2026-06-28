class List < ApplicationRecord
  belongs_to :user
  has_many :list_items, dependent: :destroy
  has_many :media, through: :list_items

  validates :name, presence: true
end
