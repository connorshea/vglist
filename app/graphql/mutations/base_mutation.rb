# typed: strict
class Mutations::BaseMutation < GraphQL::Schema::Mutation
  extend T::Sig

  # This is used for generating payload types
  object_class Types::BaseObject
  # This is used for return fields on the mutation's payload
  field_class Types::BaseField

  # Validate that the user's token has the 'write' scope.
  sig { params(_args: T.untyped).returns(T::Boolean) }
  def ready?(**_args)
    raise GraphQL::ExecutionError, "Your token must have the 'write' scope to perform a mutation." unless context[:doorkeeper_scopes]&.include?('write')

    return true
  end
end
