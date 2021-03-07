# typed: true
module Resolvers
  class WikidataBlocklistResolver < Resolvers::BaseResolver
    type Types::WikidataBlocklistEntryType.connection_type, null: true

    description "List all Wikidata blocklist entries. **Only available to admins.**"

    sig { returns(T.nilable(WikidataBlocklist::RelationType)) }
    def resolve
      WikidataBlocklist.all
    end

    sig { returns(T::Boolean) }
    def authorized?
      raise GraphQL::ExecutionError, "Viewing the Wikidata Blocklist is only available to admins." unless AdminPolicy.new(@context[:current_user], nil).wikidata_blocklist?

      true
    end
  end
end
