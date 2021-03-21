# typed: true
class Mutations::Genres::DeleteGenre < Mutations::BaseMutation
  description "Delete a game genre. **Only available to moderators and admins.** **Not available in production for now.**"

  argument :genre_id, ID, required: true, description: 'The ID of the genre to delete.'

  field :deleted, Boolean, null: true, description: "Whether the genre was successfully deleted."

  sig { params(genre_id: T.any(String, Integer)).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(genre_id:)
    genre = Genre.find(genre_id)

    raise GraphQL::ExecutionError, genre.errors.full_messages.join(", ") unless genre.destroy

    {
      deleted: true
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    genre = Genre.find(object[:genre_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this genre." unless GenrePolicy.new(@context[:current_user], genre).destroy?

    return true
  end
end
