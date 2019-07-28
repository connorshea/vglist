# typed: true
class RenameScoreToRating < ActiveRecord::Migration[5.2]
  def change
    change_table :game_purchases do |t|
      t.rename :score, :rating
    end
  end
end
