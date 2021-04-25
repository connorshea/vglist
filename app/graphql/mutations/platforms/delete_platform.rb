# typed: true
class Mutations::Platforms::DeletePlatform < Mutations::BaseMutation
  description "Delete a game platform. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :platform_id, ID, required: true, description: 'The ID of the platform to delete.'

  field :deleted, Boolean, null: true, description: "Whether the platform was successfully deleted."

  sig { params(platform_id: T.any(String, Integer)).returns(T::Hash[Symbol, T::Boolean]) }
  def resolve(platform_id:)
    platform = Platform.find(platform_id)

    raise GraphQL::ExecutionError, platform.errors.full_messages.join(", ") unless platform.destroy

    {
      deleted: true
    }
  end

  sig { params(object: T.untyped).returns(T::Boolean) }
  def authorized?(object)
    require_permissions!(:first_party)

    platform = Platform.find(object[:platform_id])
    raise GraphQL::ExecutionError, "You aren't allowed to delete this platform." unless PlatformPolicy.new(@context[:current_user], platform).destroy?

    return true
  end
end
