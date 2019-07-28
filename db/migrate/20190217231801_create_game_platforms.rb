# typed: true
class CreateGamePlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table :game_platforms do |t|
      t.references :game, null: false
      t.references :platform, null: false

      t.timestamps
    end

    add_foreign_key :game_platforms, :games,
      on_delete: :cascade
    add_foreign_key :game_platforms, :platforms,
      on_delete: :cascade
  end
end
