class CreateGamePurchaseStores < ActiveRecord::Migration[6.0]
  def change
    create_table :game_purchase_stores do |t|
      t.references :game_purchase, null: false
      t.references :store, null: false

      t.timestamps
    end

    add_foreign_key :game_purchase_stores, :game_purchases,
      on_delete: :cascade
    add_foreign_key :game_purchase_stores, :stores,
      on_delete: :cascade

    add_index :game_purchase_stores, [:game_purchase_id, :store_id],
      unique: true, name: :index_game_purchase_stores_on_game_purchase_and_store
  end
end
