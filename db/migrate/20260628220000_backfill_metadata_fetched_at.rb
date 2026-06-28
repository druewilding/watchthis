class BackfillMetadataFetchedAt < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE media SET metadata_fetched_at = created_at WHERE metadata_fetched_at IS NULL"
  end

  def down; end
end
