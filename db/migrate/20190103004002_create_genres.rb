class CreateGenres < ActiveRecord::Migration[5.2]
  def change
    create_table :genres do |t|
      t.text :name, null: false, default: ""
      t.text :description, null: false, default: ""

      t.timestamps
    end

    create_join_table :games, :genres

    add_index :games_genres, :game_id
    add_index :games_genres, :genre_id
  end
end
