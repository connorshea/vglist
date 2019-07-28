# typed: true
class AddUniqueIndexToFavorites < ActiveRecord::Migration[5.2]
  def change
    add_index :favorites, [:favoritable_id, :favoritable_type, :user_id],
      unique: true,
      name: :index_favorites_on_favoritable_id_type_and_user_id
  end
end
