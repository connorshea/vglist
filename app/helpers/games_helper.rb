# typed: strict
module GamesHelper
  extend T::Sig

  # Checks if the user has the given game in their library.
  # This is probably pretty slow and should be optimized.
  sig { params(game: Game).returns(T::Boolean) }
  def game_in_user_library?(game)
    return current_user&.game_purchases&.find_by(game_id: game.id).present?
  end

  sig { params(game: Game).returns(T::Boolean) }
  def game_in_user_favorites?(game)
    return current_user&.favorite_games&.find_by(game_id: game.id).present?
  end

  sig { params(sort: T.nilable(Symbol), humanized_name: String).returns(T.untyped) }
  def sort_dropdown_link(sort, humanized_name)
    # Merge the params to preserve any other filters.
    if sort.nil?
      dropdown_link = link_to(humanized_name, request.params.merge(order_by: nil), class: "dropdown-item#{params[:order_by].nil? ? ' has-text-weight-bold' : ''}")
    else
      dropdown_link = link_to(humanized_name, request.params.merge(order_by: sort), class: "dropdown-item#{params[:order_by] == sort.to_s ? ' has-text-weight-bold' : ''}")
    end

    return dropdown_link
  end
end
