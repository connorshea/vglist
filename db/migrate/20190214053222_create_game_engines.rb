# typed: true
class CreateGameEngines < ActiveRecord::Migration[5.2]
  def change
    create_table :game_engines do |t|
      t.references :game, null: false
      t.references :engine, null: false

      t.timestamps
    end

    add_foreign_key :game_engines, :games,
      on_delete: :cascade
    add_foreign_key :game_engines, :engines,
      on_delete: :cascade
  end
end
