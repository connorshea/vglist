# typed: true
class CreateGamePurchaseEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :game_purchase_events, id: :uuid do |t|
      t.references :user, null: false
      t.references :game_purchase, null: false

      t.timestamps
    end
  end
end
