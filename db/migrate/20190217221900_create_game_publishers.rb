# typed: true
class CreateGamePublishers < ActiveRecord::Migration[5.2]
  def change
    create_table :game_publishers do |t|
      t.references :game, null: false
      t.references :company, null: false

      t.timestamps
    end

    add_foreign_key :game_publishers, :games,
      on_delete: :cascade
    add_foreign_key :game_publishers, :companies,
      on_delete: :cascade
  end
end
