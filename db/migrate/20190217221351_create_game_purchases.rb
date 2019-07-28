# typed: true
class CreateGamePurchases < ActiveRecord::Migration[5.2]
  def change
    create_table :game_purchases do |t|
      t.references :game, null: false
      t.references :user, null: false
      t.text :comment, null: false, default: ""
      t.date :purchase_date, null: true
      t.timestamps
    end

    add_foreign_key :game_purchases, :games, on_delete: :cascade
    add_foreign_key :game_purchases, :users, on_delete: :cascade
  end
end
