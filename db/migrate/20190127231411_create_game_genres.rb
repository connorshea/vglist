# typed: true
class CreateGameGenres < ActiveRecord::Migration[5.2]
  def change
    create_table :game_genres do |t|
      t.references :game, null: false
      t.references :genre, null: false

      t.timestamps
    end

    add_foreign_key :game_genres, :games,
      on_delete: :cascade
    add_foreign_key :game_genres, :genres,
      on_delete: :cascade
  end
end
