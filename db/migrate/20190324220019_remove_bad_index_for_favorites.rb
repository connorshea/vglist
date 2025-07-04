class RemoveBadIndexForFavorites < ActiveRecord::Migration[5.2]
  def change
    remove_index :favorites, [:favoritable_id, :favoritable_type]
  end
end
