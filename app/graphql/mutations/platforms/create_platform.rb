# typed: true
class Mutations::Platforms::CreatePlatform < Mutations::BaseMutation
  description "Create a new game platform. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :name, String, required: true, description: 'The name of the platform.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the platform item in Wikidata.'

  field :platform, Types::PlatformType, null: true, description: "The platform that was created."

  sig { params(name: String, wikidata_id: T.nilable(T.any(String, Integer))).returns(T::Hash[Symbol, Platform]) }
  def resolve(name:, wikidata_id: nil)
    platform = Platform.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, platform.errors.full_messages.join(", ") unless platform.save

    {
      platform: platform
    }
  end

  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    require_permissions!(:first_party)

    raise GraphQL::ExecutionError, "You aren't allowed to create a platform." unless PlatformPolicy.new(@context[:current_user], nil).create?

    return true
  end
end
