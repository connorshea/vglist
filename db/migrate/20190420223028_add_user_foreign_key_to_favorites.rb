class AddUserForeignKeyToFavorites < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :favorites, :users, column: :user_id, on_delete: :cascade
  end
end
