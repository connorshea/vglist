# typed: true
class Mutations::Genres::CreateGenre < Mutations::BaseMutation
  description "Create a new game genre. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the genre.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the genre item in Wikidata.'

  field :genre, Types::GenreType, null: true, description: "The genre that was created."

  sig { params(name: String, wikidata_id: T.nilable(T.any(String, Integer))).returns(T::Hash[Symbol, Genre]) }
  def resolve(name:, wikidata_id: nil)
    genre = Genre.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, genre.errors.full_messages.join(", ") unless genre.save

    {
      genre: genre
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create a genre." unless GenrePolicy.new(@context[:current_user], nil).create?

    return true
  end
end
