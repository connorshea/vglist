# typed: strict
module Types
  class RelationshipType < Types::BaseObject
    description "This represents the relationship between two users, where one user is following another."

    field :id, ID, null: false, description: "ID of the relationship."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this relationship was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this relationship was last updated."

    # Associations
    field :follower, UserType, null: false, description: "The user that's following the other."
    field :followed, UserType, null: false, description: "The user being followed."
  end
end
