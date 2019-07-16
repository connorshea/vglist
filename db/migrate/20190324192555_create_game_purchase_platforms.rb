# typed: true
class CreateGamePurchasePlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table :game_purchase_platforms do |t|
      t.references :game_purchase, null: false
      t.references :platform, null: false

      t.timestamps
    end

    add_foreign_key :game_purchase_platforms, :game_purchases,
      on_delete: :cascade
    add_foreign_key :game_purchase_platforms, :platforms,
      on_delete: :cascade

    add_index :game_purchase_platforms, [:game_purchase_id, :platform_id],
      unique: true,
      name: :index_game_purchase_platforms_on_game_purchase_and_platform
  end
end
