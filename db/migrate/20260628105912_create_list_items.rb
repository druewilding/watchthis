class CreateListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :list_items do |t|
      t.references :list, null: false, foreign_key: true
      t.references :media, null: false, foreign_key: true
      t.references :share, foreign_key: true
      t.string :status, default: "pending", null: false
      t.datetime :watched_at
      t.text :notes
      t.integer :position

      t.timestamps
    end

    add_index :list_items, [:list_id, :status, :created_at]
  end
end
