# typed: true
class AddSeriesToGames < ActiveRecord::Migration[5.2]
  def change
    add_reference :games, :series, index: true
  end
end
