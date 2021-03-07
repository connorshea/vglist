# typed: true
class Mutations::GamePurchases::AddGameToLibrary < Mutations::BaseMutation
  description "Add a game to the current user's library."

  argument :game_id, ID, required: true, description: "ID of game to add."
  argument :completion_status, Types::GamePurchaseCompletionStatusType, required: false, description: "How far the user has gotten in the game."
  argument :rating, Integer, required: false, description: "The game rating (out of 100)."
  argument :hours_played, Float, required: false, description: "The number of hours a game has been played."
  argument :replay_count, Integer, required: false, description: "The number of times a game has been replayed."
  argument :comments, String, required: false, description: "Comments about the game."
  argument :start_date, GraphQL::Types::ISO8601Date, required: false, description: "The date on which the user started the game."
  argument :completion_date, GraphQL::Types::ISO8601Date, required: false, description: "The date on which the user completed the game."
  argument :platforms, [ID, { null: true }], required: false, description: "The IDs of platforms that the game is owned on."
  argument :stores, [ID, { null: true }], required: false, description: "The IDs of stores that the game is owned on."

  field :game_purchase, Types::GamePurchaseType, null: true, description: "The game purchase that's been added to the user's library."

  sig do
    params(
      game_id: T.any(String, Integer),
      completion_status: T.nilable(T.untyped),
      rating: T.nilable(Integer),
      hours_played: T.nilable(Float),
      replay_count: Integer,
      comments: String,
      start_date: T.nilable(Date),
      completion_date: T.nilable(Date),
      platforms: T::Array[T.any(String, Integer)],
      stores: T::Array[T.any(String, Integer)]
    ).returns(T::Hash[Symbol, GamePurchase])
  end
  def resolve(
    game_id:,
    completion_status: nil,
    rating: nil,
    hours_played: nil,
    replay_count: 0,
    comments: "",
    start_date: nil,
    completion_date: nil,
    platforms: [],
    stores: []
  )
    game = Game.find(game_id)

    game_purchase = GamePurchase.create(
      user: @context[:current_user],
      game: game,
      completion_status: completion_status,
      rating: rating,
      hours_played: hours_played,
      replay_count: replay_count,
      comments: comments,
      start_date: start_date,
      completion_date: completion_date,
      platform_ids: platforms,
      store_ids: stores
    )

    raise GraphQL::ExecutionError, game_purchase.errors.full_messages.join(", ") unless game_purchase.save

    {
      game_purchase: game_purchase
    }
  end

  # Check that the user is authorized to add the game to their library.
  sig { params(_object: T::Hash[T.untyped, T.untyped]).returns(T.nilable(T::Boolean)) }
  def authorized?(_object)
    raise GraphQL::ExecutionError, "You aren't allowed to add this game to your library." unless GamePurchasePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
