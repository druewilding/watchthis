class CreateLists < ActiveRecord::Migration[8.1]
  def change
    create_table :lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :is_default, default: false, null: false
      t.boolean :is_private, default: true, null: false

      t.timestamps
    end
  end
end
