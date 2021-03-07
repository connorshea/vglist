# typed: strict
module Types
  class WikidataBlocklistEntryType < Types::BaseObject
    description <<~MARKDOWN
      Entries in the Wikidata Blocklist, for blocking the creation of games
      with a given Wikidata ID. Mainly used for things we don't want to track,
      such as DLC or things that aren't _really_ games but are declared as
      games in Wikidata.
    MARKDOWN

    field :id, ID, null: false, description: "ID of the Wikidata Blocklist entry."
    field :name, String, null: false, description: "Name of the game that has been blocked."
    field :wikidata_id, Integer, null: false, description: "The blocked Wikidata ID."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this blocklist entry was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this blocklist entry was last updated."

    # Associations
    field :user, UserType, null: true, description: "User that created this blocklist entry, can be null if the user deleted their account."
  end
end
