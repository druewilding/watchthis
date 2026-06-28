class FetchMediaMetadataJob < ApplicationJob
  queue_as :default

  def perform(media_id)
    media = Media.find_by(id: media_id)
    media&.fetch_and_update_metadata!
  end
end
