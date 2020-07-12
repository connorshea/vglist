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
    # Update all relevant game purchases and favorites, delete game purchases
    # and favorites if a user has both of these games owned/favorited.
    handle_purchases
    handle_favorites

    # Reload to make sure that destroying game_b doesn't attempt to destroy
    # favorites or game purchases that are no longer associated with it.
    @game_b.reload

    # Delete Game B.
    @game_b.destroy!

    return true
  end

  private

  sig { void }
  def handle_purchases
    game_a_purchasers = @game_a.game_purchases.pluck(:user_id)
    game_b_purchasers = @game_b.game_purchases.pluck(:user_id)
    users_who_own_both_games = game_a_purchasers & game_b_purchasers

    users_who_own_both_games.each do |user_id|
      GamePurchase.find_by(game_id: @game_b.id, user_id: user_id)&.destroy!
    end

    # Update all the game purchase records
    @game_b.game_purchases.update_all(game_id: @game_a.id) # rubocop:disable Rails/SkipsModelValidations
  end

  sig { void }
  def handle_favorites
    game_a_favoriters = @game_a.favorites.pluck(:user_id)
    game_b_favoriters = @game_b.favorites.pluck(:user_id)
    users_who_favorited_both_games = game_a_favoriters & game_b_favoriters

    users_who_favorited_both_games.each do |user_id|
      FavoriteGame.find_by(game_id: @game_b.id, user_id: user_id)&.destroy!
    end

    # Update all the game favorite records
    @game_b.favorites.update_all(game_id: @game_a.id) # rubocop:disable Rails/SkipsModelValidations
  end
end
