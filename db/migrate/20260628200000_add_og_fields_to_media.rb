class AddOgFieldsToMedia < ActiveRecord::Migration[8.1]
  def change
    add_column :media, :description, :text
    add_column :media, :site_name, :string
  end
end
