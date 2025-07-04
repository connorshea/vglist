class Mutations::Genres::DeleteGenre < Mutations::BaseMutation
  description "Delete a game genre. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :genre_id, ID, required: true, description: 'The ID of the genre to delete.'

  field :deleted, Boolean, null: true, description: "Whether the genre was successfully deleted."

  def resolve(genre_id:)
    genre = Genre.find(genre_id)

    raise GraphQL::ExecutionError, genre.errors.full_messages.join(", ") unless genre.destroy

    {
      deleted: true
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    genre = Genre.find(object[:genre_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this genre." unless GenrePolicy.new(@context[:current_user], genre).destroy?

    return true
  end
end
