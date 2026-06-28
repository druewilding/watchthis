class ListItem < ApplicationRecord
  belongs_to :list
  belongs_to :media
  belongs_to :share, optional: true

  validates :status, inclusion: {in: %w[pending watched archived]}
end
