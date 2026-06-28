class CreateShares < ActiveRecord::Migration[8.1]
  def change
    create_table :shares do |t|
      t.references :from_user, null: false, foreign_key: {to_table: :users}
      t.references :to_user, null: false, foreign_key: {to_table: :users}
      t.references :media, null: false, foreign_key: true
      t.string :message
      t.string :status, default: "pending", null: false
      t.datetime :watched_at

      t.timestamps
    end

    add_index :shares, [:to_user_id, :status, :created_at]
    add_index :shares, [:from_user_id, :created_at]
  end
end
