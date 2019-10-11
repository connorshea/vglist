# typed: true
class Mutations::BaseMutation < GraphQL::Schema::Mutation
  # This is used for generating payload types
  object_class Types::BaseObject
  # This is used for return fields on the mutation's payload
  field_class Types::BaseField
end
