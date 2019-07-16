# typed: true
class AddPcgwIdToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :pcgamingwiki_id, :text
  end
end
