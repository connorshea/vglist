class AddReleaseDatesToGames < ActiveRecord::Migration[5.2]
  def change
    change_table :games, bulk: true do |t|
      t.jsonb :release_dates
      t.date :earliest_release_date
    end
  end
end
