# typed: true
class CreateReleasePurchases < ActiveRecord::Migration[5.2]
  def change
    create_table :release_purchases do |t|
      t.references :release, null: false
      t.references :user, null: false
      t.text :comment, null: false, default: ""
      t.date :purchase_date, null: true
      t.timestamps
    end
    add_foreign_key :release_purchases, :releases, on_delete: :cascade
    add_foreign_key :release_purchases, :users, on_delete: :cascade
  end
end
