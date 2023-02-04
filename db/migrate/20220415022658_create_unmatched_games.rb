# typed: true
class CreateUnmatchedGames < ActiveRecord::Migration[6.1]
  def change
    create_table :unmatched_games, comment: 'Games imported from a third party service, such as Steam, that we weren\'t able to match to a game in vglist.' do |t|
      t.references :user, null: true, comment: 'The ID of the user that tried to import this game, can be null if the user deleted their account.'
      t.text :external_service_id, comment: 'The ID of the game on the external service, e.g. the Steam AppID.'
      t.text :external_service_name, comment: 'The name of the service we\'re trying to import from, e.g. Steam.'
      t.text :name, comment: 'The name of the game that was imported.'
      t.timestamps

      # Prevent the same game from being added to this list multiple times by
      # the same user. Ignore this check for cases where the user is null, to
      # prevent problems if a user deletes their account.
      t.index [:user_id, :external_service_id, :external_service_name],
        name: 'index_unmatched_games_on_game_per_user',
        unique: true,
        where: 'user_id IS NOT NULL'

      # Create an index of service ID and service name for optimization.
      t.index [:external_service_id, :external_service_name], name: 'index_unmatched_games_on_service_id_and_name'
    end

    # Sorbet doesn't know about this method yet, so abuse T.unsafe.
    T.unsafe(self).add_check_constraint :unmatched_games, "external_service_name IN ('Steam')", name: 'validate_external_service_name'
  end
end
