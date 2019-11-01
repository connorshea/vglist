# typed: false
class MoveSteamAppIdsToSeparateModel < ActiveRecord::Migration[6.0]
  def up
    # Find all games with Steam AppIDs and move them to the steam_app_ids table.
    # Then remove the column from games.
    Game.where.not(steam_app_id: nil).each do |game|
      SteamAppId.create(
        app_id: game.steam_app_id,
        game_id: game.id
      )
    end

    remove_column :games, :steam_app_id, :integer
  end

  def down
    add_column :games, :steam_app_id, :integer

    SteamAppId.all.each do |steam_app_id|
      Game.find(steam_app_id.game_id).update(
        steam_app_id: steam_app_id.app_id
      )
      steam_app_id.destroy!
    end
  end
end
