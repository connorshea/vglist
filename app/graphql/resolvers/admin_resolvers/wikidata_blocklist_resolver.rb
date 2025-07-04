# typed: true
module Resolvers::AdminResolvers
  class WikidataBlocklistResolver < Resolvers::BaseResolver
    type Types::WikidataBlocklistEntryType.connection_type, null: true

    description "List all Wikidata blocklist entries. **Only available to admins.**"

    def resolve
      WikidataBlocklist.all
    end

    def authorized?
      raise GraphQL::ExecutionError, "Viewing the Wikidata Blocklist is only available to admins." unless AdminPolicy.new(@context[:current_user], nil).wikidata_blocklist?

      true
    end
  end
end
