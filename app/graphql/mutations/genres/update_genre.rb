# typed: true
class Mutations::Genres::UpdateGenre < Mutations::BaseMutation
  description "Update an existing game genre. **Only available to moderators and admins.** **Not available in production for now.**"

  argument :genre_id, ID, required: true, description: 'The ID of the genre record.'
  argument :name, String, required: false, description: 'The name of the genre.'
  argument :wikidata_id, Integer, required: false, description: 'The ID of the genre item in Wikidata.'

  field :genre, Types::GenreType, null: false, description: "The genre that was updated."

  # Use **args so we don't replace existing fields that aren't provided with `nil`.
  sig { params(genre_id: T.any(String, Integer), args: T.untyped).returns(T::Hash[Symbol, Genre]) }
  def resolve(genre_id:, **args)
    genre = Genre.find(genre_id)

    raise GraphQL::ExecutionError, genre.errors.full_messages.join(", ") unless genre.update(**args)

    {
      genre: genre
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    genre = Genre.find(object[:genre_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this genre." unless GenrePolicy.new(@context[:current_user], genre).update?

    return true
  end
end
