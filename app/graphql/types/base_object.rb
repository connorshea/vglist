# typed: true
module Types
  class BaseObject < GraphQL::Schema::Object
    include Pundit

    connection_type_class(Types::BaseConnectionObject)

    # User needs to be logged in to get anything from the API.
    def self.authorized?(_object, context)
      raise GraphQL::ExecutionError, "You must be logged in to use the API." if context[:current_user].nil?

      return true
    end
  end
end
