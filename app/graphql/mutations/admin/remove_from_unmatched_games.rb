# typed: true
class Mutations::Admin::RemoveFromUnmatchedGames < Mutations::BaseMutation
  description "Remove game from Unmatched Games list. **Only available to admins using a first-party OAuth Application.**"

  argument :external_service_id, ID, required: true, description: 'The ID of the game on the external service.'
  argument :external_service_name, Types::Enums::UnmatchedGameExternalServiceType, required: true, description: 'The name of the external service.'

  field :deleted, Boolean, null: false, description: "Whether the UnmatchedGame entries were deleted."

  sig { params(external_service_id: T.any(String, Integer), external_service_name: String).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(external_service_id:, external_service_name:)
    unmatched_games = UnmatchedGame.where(
      external_service_id: external_service_id,
      external_service_name: external_service_name
    )

    raise GraphQL::ExecutionError, 'No UnmatchedGame records could be found with this External Service ID and Name.' if unmatched_games.empty?

    raise GraphQL::ExecutionError, 'Unable to destroy Unmatched Game record(s).' unless unmatched_games.destroy_all

    {
      deleted: true
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to remove Unmatched Game entries." unless Admin::UnmatchedGamesPolicy.new(@context[:current_user], nil).destroy?

    return true
  end
end
