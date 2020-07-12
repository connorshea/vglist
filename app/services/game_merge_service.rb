# typed: true

# A service for merging two games together.
class GameMergeService
  extend T::Sig

  sig { returns(Game) }
  attr_accessor :game_a
  sig { returns(Game) }
  attr_accessor :game_b

  sig { params(game_a: Game, game_b: Game).void }
  def initialize(game_a, game_b)
    @game_a = game_a
    @game_b = game_b
  end

  # Merge the two games together.
  sig { returns(T::Boolean) }
  def merge!
    # Update all the game purchase records
    # TODO: Handle the case where a user has both games in their library.
    @game_b.game_purchases.update_all(game_id: @game_a.id)
    # Update all the game favorite records
    # TODO: Handle the case where a user has both games in their library.
    @game_b.favorites.update_all(game_id: @game_a.id)

    # Reload to make sure that destroying game_b doesn't attempt to destroy
    # favorites or game purchases that are no longer associated with it.
    @game_b.reload

    # Delete Game B.
    @game_b.destroy!
    return true
  end
end
