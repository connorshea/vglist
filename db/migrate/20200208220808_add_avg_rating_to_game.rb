# typed: true
class AddAvgRatingToGame < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :avg_rating, :float, scale: 1

    say_with_time "Updating games with average ratings..." do
      Game.all.each do |game|
        average = GamePurchase.where(game_id: game.id).average(:rating)
        average.nil? ? game.update(avg_rating: nil) : game.update(avg_rating: average.round(1))
      end
    end
  end
end
