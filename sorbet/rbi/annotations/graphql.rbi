# typed: strong

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

module GraphQL
  class << self
    sig { params(graphql_string: String, tracer: T.untyped).returns(GraphQL::Language::Nodes::Document) }
    def parse(graphql_string, tracer: T.unsafe(nil)); end
  end
end

class GraphQL::Backtrace
  include ::Enumerable
  extend ::Forwardable
  Elem = type_member {
  { fixed: T.untyped }
}
end

class GraphQL::Schema
  class << self
    sig { params(query_str: String, kwargs: T.untyped).returns(T::Hash[String, T.untyped]) }
    def execute(query_str = T.unsafe(nil), **kwargs); end
  end
end

class GraphQL::Schema::InputObject < ::GraphQL::Schema::Member
  sig { returns(GraphQL::Query::Context) }
  def context; end
end

class GraphQL::Schema::Object < ::GraphQL::Schema::Member
  extend ::GraphQL::Schema::Member::HasFields

  sig { returns(GraphQL::Query::Context) }
  def context; end
end

class GraphQL::Schema::Resolver
  extend ::GraphQL::Schema::Member::BaseDSLMethods

  sig { returns(GraphQL::Query::Context) }
  def context; end
end

class GraphQL::Schema::Member
  extend ::GraphQL::Schema::Member::BaseDSLMethods
end

module GraphQL::Schema::Member::HasFields
  sig { params(args: T.untyped, kwargs: T.untyped, block: T.nilable(T.proc.bind(GraphQL::Schema::Field).void)).returns(T.untyped) }
  def field(*args, **kwargs, &block); end
end

module GraphQL::Schema::Member::BaseDSLMethods
  sig { params(new_description: String).returns(T.nilable(String)) }
  def description(new_description = T.unsafe(nil)); end
end

module GraphQL::Schema::Interface
  mixes_in_class_methods ::GraphQL::Schema::Member::BaseDSLMethods
  mixes_in_class_methods ::GraphQL::Schema::Member::HasFields
end

class GraphQL::Schema::Mutation < ::GraphQL::Schema::Resolver
  extend ::GraphQL::Schema::Member::HasFields
end

class GraphQL::Schema::Subscription < ::GraphQL::Schema::Resolver
  extend ::GraphQL::Schema::Member::HasFields
end
