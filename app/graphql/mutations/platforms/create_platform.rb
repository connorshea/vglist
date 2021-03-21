# typed: true
class Mutations::Platforms::CreatePlatform < Mutations::BaseMutation
  description "Create a new game platform. **Only available to moderators and admins.** **Not available in production for now.**"

  argument :name, String, required: true, description: 'The name of the platform.'
  argument :wikidata_id, Integer, required: false, description: 'The ID of the platform item in Wikidata.'

  field :platform, Types::PlatformType, null: true, description: "The platform that was created."

  sig { params(name: String, wikidata_id: T.nilable(Integer)).returns(T::Hash[Symbol, Platform]) }
  def resolve(name:, wikidata_id: nil)
    platform = Platform.new(name: name, wikidata_id: wikidata_id)

    raise GraphQL::ExecutionError, platform.errors.full_messages.join(", ") unless platform.save

    {
      platform: platform
    }
  end

  # TODO: Put this mutation behind the "first party" OAuth application flag.
  sig { params(_object: T.untyped).returns(T::Boolean) }
  def authorized?(_object)
    # TODO: Remove this line when the first-party OAuth applications are ready.
    return false if Rails.env.production?

    raise GraphQL::ExecutionError, "You aren't allowed to create a platform." unless PlatformPolicy.new(@context[:current_user], nil).create?

    return true
  end
end
