class CreateGameDevelopers < ActiveRecord::Migration[5.2]
  def change
    create_table :game_developers do |t|
      t.references :game, null: false
      t.references :company, null: false

      t.timestamps
    end

    add_foreign_key :game_developers, :games,
      on_delete: :cascade
    add_foreign_key :game_developers, :companies,
      on_delete: :cascade
  end
end
