# typed: strict
module Types
  class StoreType < Types::BaseObject
    description "Stores where video games are sold, e.g. Steam or the Epic Games Store"

    field :id, ID, null: false
    field :name, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this store was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this store was last updated."
  end
end
