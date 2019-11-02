# typed: true
class RemoveDescriptionFromGames < ActiveRecord::Migration[6.0]
  def change
    remove_column :games, :description, :text
  end
end
