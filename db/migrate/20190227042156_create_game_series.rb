class CreateGameSeries < ActiveRecord::Migration[5.2]
  def change
    create_table :game_series do |t|
      t.references :game, null: false
      t.references :series, null: false

      t.timestamps
    end

    add_foreign_key :game_series, :games,
      on_delete: :cascade
    add_foreign_key :game_series, :series,
      on_delete: :cascade
  end
end
