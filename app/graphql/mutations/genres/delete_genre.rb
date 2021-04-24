# typed: true
class Mutations::Genres::DeleteGenre < Mutations::BaseMutation
  description "Delete a game genre. **Only available to moderators and admins using a first-party OAuth Application.**"

  required_permissions :first_party

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

  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    genre = Genre.find(object[:genre_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this genre." unless GenrePolicy.new(@context[:current_user], genre).destroy?

    return true
  end
end
