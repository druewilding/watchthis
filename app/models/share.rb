class Share < ApplicationRecord
  belongs_to :from_user, class_name: "User"
  belongs_to :to_user, class_name: "User"
  belongs_to :media

  has_one :list_item, dependent: :destroy

  validates :status, inclusion: {in: %w[pending watched archived]}

  after_create :add_to_inbox

  def self_share?
    from_user_id == to_user_id
  end

  def mark_watched!
    update!(status: "watched", watched_at: Time.current)
    list_item&.update!(status: "watched", watched_at: Time.current)
  end

  private

  def add_to_inbox
    inbox = to_user.inbox
    return unless inbox

    inbox.list_items.create!(media: media, share: self)
  end
end
