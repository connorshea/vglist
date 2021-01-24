# typed: true
class AddUniqueIndexForIgdbIds < ActiveRecord::Migration[6.1]
  def change
    add_index :games, :igdb_id, unique: true
  end
end
