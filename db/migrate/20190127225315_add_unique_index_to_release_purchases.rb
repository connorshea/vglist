class AddUniqueIndexToReleasePurchases < ActiveRecord::Migration[5.2]
  def change
    add_index :release_purchases, [:release_id, :user_id], unique: true
  end
end
