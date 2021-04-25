# typed: true
class Mutations::BaseMutation < GraphQL::Schema::Mutation
  extend T::Sig

  # This is used for generating payload types
  object_class Types::BaseObject
  # This is used for return fields on the mutation's payload
  field_class Types::BaseField

  # The permissions required to perform this mutation. Currently this method
  # only accepts `:first_party`, but may accept other permission types in the
  # future.
  sig { params(permissions: Symbol).void }
  def require_permissions!(*permissions)
    error_msg = "Your token must be from a first-party OAuth application to perform this mutation."
    raise GraphQL::ExecutionError, error_msg if !@context[:first_party] && permissions.include?(:first_party)
  end

  # Validate that the user's token has the 'write' scope and check for a
  # first-party token if necessary.
  sig { params(_args: T.untyped).returns(T::Boolean) }
  def ready?(**_args)
    # Make sure the doorkeeper scopes include write.
    # Skip this check if the user is using token authentication.
    raise GraphQL::ExecutionError, "Your token must have the 'write' scope to perform a mutation." if !@context[:token_auth] &&
                                                                                                      !@context[:doorkeeper_scopes]&.include?('write')

    return true
  end
end
