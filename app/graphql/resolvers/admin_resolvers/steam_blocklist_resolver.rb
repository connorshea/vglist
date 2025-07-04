module Resolvers::AdminResolvers
  class SteamBlocklistResolver < Resolvers::BaseResolver
    type Types::SteamBlocklistEntryType.connection_type, null: true

    description "List all steam blocklist entries. **Only available to admins.**"

    def resolve
      SteamBlocklist.all
    end

    def authorized?
      raise GraphQL::ExecutionError, "Viewing the Steam Blocklist is only available to admins." unless AdminPolicy.new(@context[:current_user], nil).steam_blocklist?

      true
    end
  end
end
