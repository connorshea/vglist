# typed: strong
module Types
  class BaseObject < GraphQL::Schema::Object
    include Pundit
  end
end
