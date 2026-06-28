class CreateMedia < ActiveRecord::Migration[8.1]
  def change
    create_table :media do |t|
      t.string :url, null: false
      t.string :normalized_url, null: false
      t.string :platform, null: false
      t.string :title
      t.string :thumbnail_url
      t.integer :duration_seconds
      t.string :author
      t.string :youtube_id
      t.datetime :published_at
      t.references :added_by, null: false, foreign_key: {to_table: :users}

      t.timestamps
    end

    add_index :media, :normalized_url, unique: true
    add_index :media, :platform
  end
end
