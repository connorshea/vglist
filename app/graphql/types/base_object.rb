# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    include Pundit::Authorization

    connection_type_class(Types::BaseConnectionObject)

    # Allow unauthenticated users to read public data.
    # When a user IS authenticated, check that they are not banned.
    def self.authorized?(_object, context)
      raise GraphQL::ExecutionError, "The user that owns this token has been banned." if context[:current_user]&.banned?

      return true
    end
  end
end
