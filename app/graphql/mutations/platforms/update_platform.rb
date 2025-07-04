class Mutations::Platforms::UpdatePlatform < Mutations::BaseMutation
  description "Update an existing game platform. **Only available to moderators and admins using a first-party OAuth Application.**"

  argument :platform_id, ID, required: true, description: 'The ID of the platform record.'
  argument :name, String, required: false, description: 'The name of the platform.'
  argument :wikidata_id, ID, required: false, description: 'The ID of the platform item in Wikidata.'

  field :platform, Types::PlatformType, null: false, description: "The platform that was updated."

  # Use **args so we don't replace existing fields that aren't provided with `nil`.
  def resolve(platform_id:, **args)
    platform = Platform.find(platform_id)

    raise GraphQL::ExecutionError, platform.errors.full_messages.join(", ") unless platform.update(**args)

    {
      platform: platform
    }
  end

  def authorized?(object)
    require_permissions!(:first_party)

    platform = Platform.find(object[:platform_id])
    raise GraphQL::ExecutionError, "You aren't allowed to update this platform." unless PlatformPolicy.new(@context[:current_user], platform).update?

    return true
  end
end
