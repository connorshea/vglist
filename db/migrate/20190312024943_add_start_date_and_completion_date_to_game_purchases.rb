# typed: true
class AddStartDateAndCompletionDateToGamePurchases < ActiveRecord::Migration[5.2]
  def change
    change_table :game_purchases, bulk: true do |t|
      t.date :start_date
      t.date :completion_date
    end
  end
end
