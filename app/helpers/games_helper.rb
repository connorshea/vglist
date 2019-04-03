module GamesHelper
  # Checks if the user has the given game in their library.
  # This is probably pretty slow and should be optimized.
  def game_in_user_library?(game)
    return current_user.game_purchases.find_by(game_id: game.id).present?
  end

  def game_in_user_favorites?(game)
    return current_user.favorites.games.find_by(favoritable_id: game.id).present?
  end
end
