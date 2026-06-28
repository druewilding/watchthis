class AddMetadataFetchedAtToMedia < ActiveRecord::Migration[8.1]
  def change
    add_column :media, :metadata_fetched_at, :datetime
  end
end
