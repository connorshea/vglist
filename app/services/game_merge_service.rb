# typed: true

# A service for merging two games together.
class GameMergeService
  extend T::Sig

  attr_accessor :game_a
  attr_accessor :game_b

  def initialize(game_a, game_b)
    @game_a = game_a
    @game_b = game_b
  end

  # Merge the two games together.
  def merge!
    # Update all the game purchase records
    # TODO: Handle the case where a user has both games in their library.
    @game_b_purchases = GamePurchase.where(game_id: @game_b.id)
    @game_b_purchases.each do |purchase|
      purchase.update(game_id: @game_a.id)
    end

    # Update all the favorites
    # TODO: Handle the case where a user has both games favorited.
    @game_b_favorites = FavoriteGame.where(game_id: @game_b.id)
    @game_b_favorites.each do |favorite|
      favorite.update(game_id: @game_a.id)
    end

    # Delete Game B.
    @game_b.destroy!
    return true
  end
end
