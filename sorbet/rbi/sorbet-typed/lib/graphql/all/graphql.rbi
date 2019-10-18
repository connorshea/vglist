# typed: false
# test_via: ../subscriptions.rb
module GraphQL
  ID_TYPE = T.let(GraphQL::Types::ID.graphql_definition, T.untyped)
  VERSION = T.let("1.10.0.pre1", T.untyped)
  INT_TYPE = T.let(GraphQL::Types::Int.graphql_definition, T.untyped)
  FLOAT_TYPE = T.let(GraphQL::Types::Float.graphql_definition, T.untyped)
  STRING_TYPE = T.let(GraphQL::Types::String.graphql_definition, T.untyped)
  BOOLEAN_TYPE = T.let(GraphQL::Types::Boolean.graphql_definition, T.untyped)

  # Turn a query string or schema definition into an AST
  # 
  # _@param_ `graphql_string` — a GraphQL query string or schema definition
  sig { params(graphql_string: String, tracer: T.untyped).returns(GraphQL::Language::Nodes::Document) }
  def self.parse(graphql_string, tracer: GraphQL::Tracing::NullTracer); end

  # Read the contents of `filename` and parse them as GraphQL
  # 
  # _@param_ `filename` — Path to a `.graphql` file containing IDL or query
  sig { params(filename: String).returns(GraphQL::Language::Nodes::Document) }
  def self.parse_file(filename); end

  sig { params(string: T.untyped, filename: T.untyped, tracer: T.untyped).returns(T.untyped) }
  def self.parse_with_racc(string, filename: nil, tracer: GraphQL::Tracing::NullTracer); end

  sig { params(graphql_string: T.untyped).returns(T::Array[GraphQL::Language::Token]) }
  def self.scan(graphql_string); end

  sig { params(graphql_string: T.untyped).returns(T.untyped) }
  def self.scan_with_ragel(graphql_string); end

  class Error < StandardError
  end

  class RequiredImplementationMissingError < GraphQL::Error
  end

  # Support Ruby 2.2 by implementing `-"str"`. If we drop 2.2 support, we can remove this backport.
  module StringDedupBackport
  end

  module Dig
    # implemented using the old activesupport #dig instead of the ruby built-in
    # so we can use some of the magic in Schema::InputObject and Query::Arguments
    # to handle stringified/symbolized keys.
    # 
    # _@param_ `args` — rgs [Array<[String, Symbol>] Retrieves the value object corresponding to the each key objects repeatedly
    sig { params(own_key: T.untyped, rest_keys: T.untyped).returns(Object) }
    def dig(own_key, *rest_keys); end
  end

  # {Field}s belong to {ObjectType}s and {InterfaceType}s.
  # 
  # They're usually created with the `field` helper. If you create it by hand, make sure {#name} is a String.
  # 
  # A field must have a return type, but if you want to defer the return type calculation until later,
  # you can pass a proc for the return type. That proc will be called when the schema is defined.
  # 
  # @example Lazy type resolution
  #   # If the field's type isn't defined yet, you can pass a proc
  #   field :city, -> { TypeForModelName.find("City") }
  # 
  # For complex field definition, you can pass a block to the `field` helper, eg `field :name do ... end`.
  # This block is equivalent to calling `GraphQL::Field.define { ... }`.
  # 
  # @example Defining a field with a block
  #   field :city, CityType do
  #     # field definition continues inside the block
  #   end
  # 
  # ## Resolve
  # 
  # Fields have `resolve` functions to determine their values at query-time.
  # The default implementation is to call a method on the object based on the field name.
  # 
  # @example Create a field which calls a method with the same name.
  #   GraphQL::ObjectType.define do
  #     field :name, types.String, "The name of this thing "
  #   end
  # 
  # You can specify a custom proc with the `resolve` helper.
  # 
  # There are some shortcuts for common `resolve` implementations:
  #   - Provide `property:` to call a method with a different name than the field name
  #   - Provide `hash_key:` to resolve the field by doing a key lookup, eg `obj[:my_hash_key]`
  # 
  # @example Create a field that calls a different method on the object
  #   GraphQL::ObjectType.define do
  #     # use the `property` keyword:
  #     field :firstName, types.String, property: :first_name
  #   end
  # 
  # @example Create a field looks up with `[hash_key]`
  #   GraphQL::ObjectType.define do
  #     # use the `hash_key` keyword:
  #     field :firstName, types.String, hash_key: :first_name
  #   end
  # 
  # ## Arguments
  # 
  # Fields can take inputs; they're called arguments. You can define them with the `argument` helper.
  # 
  # @example Create a field with an argument
  #   field :students, types[StudentType] do
  #     argument :grade, types.Int
  #     resolve ->(obj, args, ctx) {
  #       Student.where(grade: args[:grade])
  #     }
  #   end
  # 
  # They can have default values which will be provided to `resolve` if the query doesn't include a value.
  # 
  # @example Argument with a default value
  #   field :events, types[EventType] do
  #     # by default, don't include past events
  #     argument :includePast, types.Boolean, default_value: false
  #     resolve ->(obj, args, ctx) {
  #       args[:includePast] # => false if no value was provided in the query
  #       # ...
  #     }
  #   end
  # 
  # Only certain types maybe used for inputs:
  # 
  # - Scalars
  # - Enums
  # - Input Objects
  # - Lists of those types
  # 
  # Input types may also be non-null -- in that case, the query will fail
  # if the input is not present.
  # 
  # ## Complexity
  # 
  # Fields can have _complexity_ values which describe the computation cost of resolving the field.
  # You can provide the complexity as a constant with `complexity:` or as a proc, with the `complexity` helper.
  # 
  # @example Custom complexity values
  #   # Complexity can be a number or a proc.
  # 
  #   # Complexity can be defined with a keyword:
  #   field :expensive_calculation, !types.Int, complexity: 10
  # 
  #   # Or inside the block:
  #   field :expensive_calculation_2, !types.Int do
  #     complexity ->(ctx, args, child_complexity) { ctx[:current_user].staff? ? 0 : 10 }
  #   end
  # 
  # @example Calculating the complexity of a list field
  #   field :items, types[ItemType] do
  #     argument :limit, !types.Int
  #     # Multiply the child complexity by the possible items on the list
  #     complexity ->(ctx, args, child_complexity) { child_complexity * args[:limit] }
  #   end
  # 
  # @example Creating a field, then assigning it to a type
  #   name_field = GraphQL::Field.define do
  #     name("Name")
  #     type(!types.String)
  #     description("The name of this thing")
  #     resolve ->(object, arguments, context) { object.name }
  #   end
  # 
  #   NamedType = GraphQL::ObjectType.define do
  #     # The second argument may be a GraphQL::Field
  #     field :name, name_field
  #   end
  class Field
    include GraphQL::Define::InstanceDefinable

    # _@return_ — True if this is the Relay find-by-id field
    sig { returns(T::Boolean) }
    def relay_node_field; end

    # _@return_ — True if this is the Relay find-by-id field
    sig { params(value: T::Boolean).returns(T::Boolean) }
    def relay_node_field=(value); end

    # _@return_ — True if this is the Relay find-by-ids field
    sig { returns(T::Boolean) }
    def relay_nodes_field; end

    # _@return_ — True if this is the Relay find-by-ids field
    sig { params(value: T::Boolean).returns(T::Boolean) }
    def relay_nodes_field=(value); end

    # _@return_ — A proc-like object which can be called to return the field's value
    sig { returns(T::Array[T.untyped]) }
    def resolve_proc; end

    # _@return_ — A proc-like object which can be called trigger a lazy resolution
    sig { returns(T::Array[T.untyped]) }
    def lazy_resolve_proc; end

    # _@return_ — The name of this field on its {GraphQL::ObjectType} (or {GraphQL::InterfaceType})
    sig { returns(String) }
    def name; end

    # _@return_ — The client-facing description of this field
    sig { returns(T.nilable(String)) }
    def description; end

    # _@return_ — The client-facing description of this field
    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def description=(value); end

    # _@return_ — The client-facing reason why this field is deprecated (if present, the field is deprecated)
    sig { returns(T.nilable(String)) }
    def deprecation_reason; end

    # _@return_ — The client-facing reason why this field is deprecated (if present, the field is deprecated)
    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def deprecation_reason=(value); end

    # _@return_ — Map String argument names to their {GraphQL::Argument} implementations
    sig { returns(T::Hash[String, GraphQL::Argument]) }
    def arguments; end

    # _@return_ — Map String argument names to their {GraphQL::Argument} implementations
    sig { params(value: T::Hash[String, GraphQL::Argument]).returns(T::Hash[String, GraphQL::Argument]) }
    def arguments=(value); end

    # _@return_ — The mutation this field was derived from, if it was derived from a mutation
    sig { returns(T.nilable(GraphQL::Relay::Mutation)) }
    def mutation; end

    # _@return_ — The mutation this field was derived from, if it was derived from a mutation
    sig { params(value: T.nilable(GraphQL::Relay::Mutation)).returns(T.nilable(GraphQL::Relay::Mutation)) }
    def mutation=(value); end

    # _@return_ — The complexity for this field (default: 1), as a constant or a proc like `->(query_ctx, args, child_complexity) { } # Numeric`
    sig { returns(T.any(Numeric, Proc)) }
    def complexity; end

    # _@return_ — The complexity for this field (default: 1), as a constant or a proc like `->(query_ctx, args, child_complexity) { } # Numeric`
    sig { params(value: T.any(Numeric, Proc)).returns(T.any(Numeric, Proc)) }
    def complexity=(value); end

    # _@return_ — The method to call on `obj` to return this field (overrides {#name} if present)
    sig { returns(T.nilable(Symbol)) }
    def property; end

    # _@return_ — The key to access with `obj.[]` to resolve this field (overrides {#name} if present)
    sig { returns(T.nilable(Object)) }
    def hash_key; end

    # _@return_ — The function used to derive this field
    sig { returns(T.any(Object, GraphQL::Function)) }
    def function; end

    # _@return_ — The function used to derive this field
    sig { params(value: T.any(Object, GraphQL::Function)).returns(T.any(Object, GraphQL::Function)) }
    def function=(value); end

    # Returns the value of attribute arguments_class
    sig { returns(T.untyped) }
    def arguments_class; end

    # Sets the attribute arguments_class
    # 
    # _@param_ `value` — the value to set the attribute arguments_class to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def arguments_class=(value); end

    # Sets the attribute connection
    # 
    # _@param_ `value` — the value to set the attribute connection to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def connection=(value); end

    # Sets the attribute introspection
    # 
    # _@param_ `value` — the value to set the attribute introspection to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def introspection=(value); end

    # _@return_ — Prefix for subscription names from this field
    sig { returns(T.nilable(String)) }
    def subscription_scope; end

    # _@return_ — Prefix for subscription names from this field
    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def subscription_scope=(value); end

    # _@return_ — True if this field should be traced. By default, fields are only traced if they are not a ScalarType or EnumType.
    sig { returns(T::Boolean) }
    def trace; end

    # _@return_ — True if this field should be traced. By default, fields are only traced if they are not a ScalarType or EnumType.
    sig { params(value: T::Boolean).returns(T::Boolean) }
    def trace=(value); end

    # Returns the value of attribute ast_node
    sig { returns(T.untyped) }
    def ast_node; end

    # Sets the attribute ast_node
    # 
    # _@param_ `value` — the value to set the attribute ast_node to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def ast_node=(value); end

    sig { returns(T::Boolean) }
    def connection?; end

    sig { returns(T.nilable(Class)) }
    def edge_class; end

    sig { params(value: T.nilable(Class)).returns(T.nilable(Class)) }
    def edge_class=(value); end

    sig { returns(T::Boolean) }
    def edges?; end

    sig { returns(T.nilable(Integer)) }
    def connection_max_page_size; end

    sig { params(value: T.nilable(Integer)).returns(T.nilable(Integer)) }
    def connection_max_page_size=(value); end

    sig { returns(Field) }
    def initialize; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    # _@return_ — Is this field a predefined introspection field?
    sig { returns(T::Boolean) }
    def introspection?; end

    # Get a value for this field
    # 
    # _@param_ `object` — The object this field belongs to
    # 
    # _@param_ `arguments` — Arguments declared in the query
    # 
    # _@param_ `context` — 
    # 
    # resolving a field value
    # ```ruby
    # field.resolve(obj, args, ctx)
    # ```
    sig { params(object: Object, arguments: T::Hash[T.untyped, T.untyped], context: GraphQL::Query::Context).returns(T.untyped) }
    def resolve(object, arguments, context); end

    # Provide a new callable for this field's resolve function. If `nil`,
    # a new resolve proc will be build based on its {#name}, {#property} or {#hash_key}.
    # 
    # _@param_ `new_resolve_proc` — 
    sig { params(new_resolve_proc: T.nilable(T::Array[T.untyped])).returns(T.untyped) }
    def resolve=(new_resolve_proc); end

    sig { params(new_return_type: T.untyped).returns(T.untyped) }
    def type=(new_return_type); end

    # Get the return type for this field.
    sig { returns(T.untyped) }
    def type; end

    sig { params(new_name: String).returns(T.untyped) }
    def name=(new_name); end

    # _@param_ `new_property` — A method to call to resolve this field. Overrides the existing resolve proc.
    sig { params(new_property: Symbol).returns(T.untyped) }
    def property=(new_property); end

    # _@param_ `new_hash_key` — A key to access with `#[key]` to resolve this field. Overrides the existing resolve proc.
    sig { params(new_hash_key: Symbol).returns(T.untyped) }
    def hash_key=(new_hash_key); end

    sig { returns(T.untyped) }
    def to_s; end

    # If {#resolve} returned an object which should be handled lazily,
    # this method will be called later to force the object to return its value.
    # 
    # _@param_ `obj` — The {#resolve}-provided object, registered with {Schema#lazy_resolve}
    # 
    # _@param_ `args` — Arguments to this field
    # 
    # _@param_ `ctx` — Context for this field
    # 
    # _@return_ — The result of calling the registered method on `obj`
    sig { params(obj: Object, args: GraphQL::Query::Arguments, ctx: GraphQL::Query::Context).returns(Object) }
    def lazy_resolve(obj, args, ctx); end

    # Assign a new resolve proc to this field. Used for {#lazy_resolve}
    sig { params(new_lazy_resolve_proc: Object).returns(T.untyped) }
    def lazy_resolve=(new_lazy_resolve_proc); end

    # Prepare a lazy value for this field. It may be `then`-ed and resolved later.
    # 
    # _@return_ — A lazy wrapper around `obj` and its registered method name
    sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(GraphQL::Execution::Lazy) }
    def prepare_lazy(obj, args, ctx); end

    sig { returns(T.untyped) }
    def type_class; end

    sig { returns(T.untyped) }
    def build_default_resolver; end

    # `metadata` can store arbitrary key-values with an object.
    # 
    # _@return_ — Hash for user-defined storage
    sig { returns(T::Hash[Object, Object]) }
    def metadata; end

    # Mutate this instance using functions from its {.definition}s.
    # Keywords or helpers in the block correspond to keys given to `accepts_definitions`.
    # 
    # Note that the block is not called right away -- instead, it's deferred until
    # one of the defined fields is needed.
    sig { params(kwargs: T.untyped, block: T.untyped).void }
    def define(**kwargs, &block); end

    # Shallow-copy this object, then apply new definitions to the copy.
    # 
    # _@return_ — A new instance, with any extended definitions
    # 
    # _@see_ `{#define}` — for arguments
    sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::Define::InstanceDefinable) }
    def redefine(**kwargs, &block); end

    # Run the definition block if it hasn't been run yet.
    # This can only be run once: the block is deleted after it's used.
    # You have to call this before using any value which could
    # come from the definition block.
    sig { void }
    def ensure_defined; end

    # Take the pending methods and put them back on this object's singleton class.
    # This reverts the process done by {#stash_dependent_methods}
    sig { void }
    def revive_dependent_methods; end

    # Find the method names which were declared as definition-dependent,
    # then grab the method definitions off of this object's class
    # and store them for later.
    # 
    # Then make a dummy method for each of those method names which:
    # 
    # - Triggers the pending definition, if there is one
    # - Calls the same method again.
    # 
    # It's assumed that {#ensure_defined} will put the original method definitions
    # back in place with {#revive_dependent_methods}.
    sig { void }
    def stash_dependent_methods; end

    module DefaultLazyResolve
      sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.call(obj, args, ctx); end
    end

    # Create resolve procs ahead of time based on a {GraphQL::Field}'s `name`, `property`, and `hash_key` configuration.
    module Resolve
      # _@param_ `field` — A field that needs a resolve proc
      # 
      # _@return_ — A resolver for this field, based on its config
      sig { params(field: GraphQL::Field).returns(Proc) }
      def create_proc(field); end

      # _@param_ `field` — A field that needs a resolve proc
      # 
      # _@return_ — A resolver for this field, based on its config
      sig { params(field: GraphQL::Field).returns(Proc) }
      def self.create_proc(field); end

      # These only require `obj` as input
      class BuiltInResolve
      end

      # Resolve the field by `public_send`ing `@method_name`
      class MethodResolve < GraphQL::Field::Resolve::BuiltInResolve
        sig { params(field: T.untyped).returns(MethodResolve) }
        def initialize(field); end

        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def call(obj, args, ctx); end
      end

      # Resolve the field by looking up `@hash_key` with `#[]`
      class HashKeyResolve < GraphQL::Field::Resolve::BuiltInResolve
        sig { params(hash_key: T.untyped).returns(HashKeyResolve) }
        def initialize(hash_key); end

        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def call(obj, args, ctx); end
      end

      # Call the field's name at query-time since
      # it might have changed
      class NameResolve < GraphQL::Field::Resolve::BuiltInResolve
        sig { params(field: T.untyped).returns(NameResolve) }
        def initialize(field); end

        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def call(obj, args, ctx); end
      end
    end
  end

  # A combination of query string and {Schema} instance which can be reduced to a {#result}.
  class Query
    include GraphQL::Tracing::Traceable
    extend Forwardable

    # Returns the value of attribute schema
    sig { returns(T.untyped) }
    def schema; end

    # Returns the value of attribute context
    sig { returns(T.untyped) }
    def context; end

    # Returns the value of attribute provided_variables
    sig { returns(T.untyped) }
    def provided_variables; end

    # The value for root types
    sig { returns(T.untyped) }
    def root_value; end

    # The value for root types
    sig { params(value: T.untyped).returns(T.untyped) }
    def root_value=(value); end

    # _@return_ — The operation name provided by client or the one inferred from the document. Used to determine which operation to run.
    sig { returns(T.nilable(String)) }
    def operation_name; end

    # _@return_ — The operation name provided by client or the one inferred from the document. Used to determine which operation to run.
    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def operation_name=(value); end

    # _@return_ — if false, static validation is skipped (execution behavior for invalid queries is undefined)
    sig { returns(T::Boolean) }
    def validate; end

    # _@return_ — if false, static validation is skipped (execution behavior for invalid queries is undefined)
    sig { params(value: T::Boolean).returns(T::Boolean) }
    def validate=(value); end

    # Sets the attribute query_string
    # 
    # _@param_ `value` — the value to set the attribute query_string to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def query_string=(value); end

    sig { returns(GraphQL::Language::Nodes::Document) }
    def document; end

    sig { returns(T.untyped) }
    def inspect; end

    # _@return_ — The name of the operation to run (may be inferred)
    sig { returns(T.nilable(String)) }
    def selected_operation_name; end

    # _@return_ — the triggered event, if this query is a subscription update
    sig { returns(T.nilable(String)) }
    def subscription_topic; end

    # Returns the value of attribute tracers
    sig { returns(T.untyped) }
    def tracers; end

    # Prepare query `query_string` on `schema`
    # 
    # _@param_ `schema` — 
    # 
    # _@param_ `query_string` — 
    # 
    # _@param_ `context` — an arbitrary hash of values which you can access in {GraphQL::Field#resolve}
    # 
    # _@param_ `variables` — values for `$variables` in the query
    # 
    # _@param_ `operation_name` — if the query string contains many operations, this is the one which should be executed
    # 
    # _@param_ `root_value` — the object used to resolve fields on the root type
    # 
    # _@param_ `max_depth` — the maximum number of nested selections allowed for this query (falls back to schema-level value)
    # 
    # _@param_ `max_complexity` — the maximum field complexity for this query (falls back to schema-level value)
    # 
    # _@param_ `except` — If provided, objects will be hidden from the schema when `.call(schema_member, context)` returns truthy
    # 
    # _@param_ `only` — If provided, objects will be hidden from the schema when `.call(schema_member, context)` returns false
    sig do
      params(
        schema: GraphQL::Schema,
        query_string: T.nilable(String),
        document: T.untyped,
        context: T.untyped,
        variables: T.nilable(T::Hash[T.untyped, T.untyped]),
        validate: T.untyped,
        subscription_topic: T.untyped,
        operation_name: T.nilable(String),
        root_value: T.nilable(Object),
        max_depth: Numeric,
        max_complexity: Numeric,
        except: T.nilable(T::Array[T.untyped]),
        only: T.nilable(T::Array[T.untyped]),
        query: T.untyped
      ).returns(Query)
    end
    def initialize(schema, query_string = nil, document: nil, context: nil, variables: nil, validate: true, subscription_topic: nil, operation_name: nil, root_value: nil, max_depth: schema.max_depth, max_complexity: schema.max_complexity, except: nil, only: nil, query: nil); end

    # If a document was provided to `GraphQL::Schema#execute` instead of the raw query string, we will need to get it from the document
    sig { returns(T.untyped) }
    def query_string; end

    sig { returns(T::Boolean) }
    def subscription_update?; end

    # A lookahead for the root selections of this query
    sig { returns(GraphQL::Execution::Lookahead) }
    def lookahead; end

    sig { params(result_hash: T.untyped).returns(T.untyped) }
    def result_values=(result_hash); end

    sig { returns(T.untyped) }
    def result_values; end

    sig { returns(T.untyped) }
    def fragments; end

    sig { returns(T.untyped) }
    def operations; end

    # Get the result for this query, executing it once
    # 
    # _@return_ — A GraphQL response, with `"data"` and/or `"errors"` keys
    sig { returns(T::Hash[T.untyped, T.untyped]) }
    def result; end

    sig { returns(T::Boolean) }
    def executed?; end

    sig { returns(T.untyped) }
    def static_errors; end

    # This is the operation to run for this query.
    # If more than one operation is present, it must be named at runtime.
    sig { returns(T.nilable(GraphQL::Language::Nodes::OperationDefinition)) }
    def selected_operation; end

    # Determine the values for variables of this query, using default values
    # if a value isn't provided at runtime.
    # 
    # If some variable is invalid, errors are added to {#validation_errors}.
    # 
    # _@return_ — Variables to apply to this query
    sig { returns(GraphQL::Query::Variables) }
    def variables; end

    sig { returns(T.untyped) }
    def irep_selection; end

    # Node-level cache for calculating arguments. Used during execution and query analysis.
    # 
    # _@return_ — Arguments for this node, merging default values, literal values and query variables
    sig { params(irep_or_ast_node: T.untyped, definition: T.untyped).returns(GraphQL::Query::Arguments) }
    def arguments_for(irep_or_ast_node, definition); end

    sig { returns(T.untyped) }
    def validation_pipeline; end

    # Returns the value of attribute analysis_errors
    sig { returns(T.untyped) }
    def analysis_errors; end

    # Sets the attribute analysis_errors
    # 
    # _@param_ `value` — the value to set the attribute analysis_errors to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def analysis_errors=(value); end

    sig { returns(T::Boolean) }
    def valid?; end

    sig { returns(T.untyped) }
    def warden; end

    # _@param_ `abstract_type` — 
    # 
    # _@param_ `value` — Any runtime value
    # 
    # _@return_ — The runtime type of `value` from {Schema#resolve_type}
    # 
    # _@see_ `{#possible_types}` — to apply filtering from `only` / `except`
    sig { params(abstract_type: T.any(GraphQL::UnionType, GraphQL::InterfaceType), value: Object).returns(T.nilable(GraphQL::ObjectType)) }
    def resolve_type(abstract_type, value = :__undefined__); end

    sig { returns(T::Boolean) }
    def mutation?; end

    sig { returns(T::Boolean) }
    def query?; end

    sig { params(only: T.untyped, except: T.untyped).void }
    def merge_filters(only: nil, except: nil); end

    sig { returns(T::Boolean) }
    def subscription?; end

    sig { params(operations: T.untyped, operation_name: T.untyped).returns(T.untyped) }
    def find_operation(operations, operation_name); end

    sig { returns(T.untyped) }
    def prepare_ast; end

    # Since the query string is processed at the last possible moment,
    # any internal values which depend on it should be accessed within this wrapper.
    sig { returns(T.untyped) }
    def with_prepared_ast; end

    # _@param_ `key` — The name of the event in GraphQL internals
    # 
    # _@param_ `metadata` — Event-related metadata (can be anything)
    # 
    # _@return_ — Must return the value of the block
    sig { params(key: String, metadata: T::Hash[T.untyped, T.untyped]).returns(Object) }
    def trace(key, metadata); end

    # If there's a tracer at `idx`, call it and then increment `idx`.
    # Otherwise, yield.
    # 
    # _@param_ `idx` — Which tracer to call
    # 
    # _@param_ `key` — The current event name
    # 
    # _@param_ `metadata` — The current event object
    # 
    # _@return_ — Whatever the block returns
    sig { params(idx: Integer, key: String, metadata: Object).returns(T.untyped) }
    def call_tracers(idx, key, metadata); end

    class OperationNameMissingError < GraphQL::ExecutionError
      sig { params(name: T.untyped).returns(OperationNameMissingError) }
      def initialize(name); end
    end

    # A result from {Schema#execute}.
    # It provides the requested data and
    # access to the {Query} and {Query::Context}.
    class Result
      extend Forwardable

      sig { params(query: T.untyped, values: T.untyped).returns(Result) }
      def initialize(query:, values:); end

      # _@return_ — The query that was executed
      sig { returns(GraphQL::Query) }
      def query; end

      # _@return_ — The resulting hash of "data" and/or "errors"
      sig { returns(T::Hash[T.untyped, T.untyped]) }
      def to_h; end

      # Delegate any hash-like method to the underlying hash.
      sig { params(method_name: T.untyped, args: T.untyped, block: T.untyped).returns(T.untyped) }
      def method_missing(method_name, *args, &block); end

      sig { params(method_name: T.untyped, include_private: T.untyped).returns(T::Boolean) }
      def respond_to_missing?(method_name, include_private = false); end

      sig { returns(T.untyped) }
      def inspect; end

      # A result is equal to another object when:
      # 
      # - The other object is a Hash whose value matches `result.to_h`
      # - The other object is a Result whose value matches `result.to_h`
      # 
      # (The query is ignored for comparing result equality.)
      sig { params(other: T.untyped).returns(T::Boolean) }
      def ==(other); end
    end

    # Expose some query-specific info to field resolve functions.
    # It delegates `[]` to the hash that's passed to `GraphQL::Query#initialize`.
    class Context
      include GraphQL::Query::Context::SharedMethods
      extend Forwardable

      # Returns the value of attribute execution_strategy
      sig { returns(T.untyped) }
      def execution_strategy; end

      sig { params(new_strategy: T.untyped).returns(T.untyped) }
      def execution_strategy=(new_strategy); end

      # _@return_ — The internal representation for this query node
      sig { returns(GraphQL::InternalRepresentation::Node) }
      def irep_node; end

      # _@return_ — The AST node for the currently-executing field
      sig { returns(GraphQL::Language::Nodes::Field) }
      def ast_node; end

      # _@return_ — errors returned during execution
      sig { returns(T::Array[GraphQL::ExecutionError]) }
      def errors; end

      # _@return_ — The query whose context this is
      sig { returns(GraphQL::Query) }
      def query; end

      sig { returns(GraphQL::Schema) }
      def schema; end

      # _@return_ — The current position in the result
      sig { returns(T::Array[T.any(String, Integer)]) }
      def path; end

      # Make a new context which delegates key lookup to `values`
      # 
      # _@param_ `query` — the query who owns this context
      # 
      # _@param_ `values` — A hash of arbitrary values which will be accessible at query-time
      sig { params(query: GraphQL::Query, values: T::Hash[T.untyped, T.untyped], object: T.untyped).returns(Context) }
      def initialize(query:, values:, object:); end

      sig { params(value: T.untyped).returns(T.untyped) }
      def interpreter=(value); end

      sig { params(value: T.untyped).returns(T.untyped) }
      def value=(value); end

      # Lookup `key` from the hash passed to {Schema#execute} as `context:`
      sig { params(key: T.untyped).returns(T.untyped) }
      def [](key); end

      # Reassign `key` to the hash passed to {Schema#execute} as `context:`
      sig { params(key: T.untyped, value: T.untyped).returns(T.untyped) }
      def []=(key, value); end

      sig { returns(GraphQL::Schema::Warden) }
      def warden; end

      # Get an isolated hash for `ns`. Doesn't affect user-provided storage.
      # 
      # _@param_ `ns` — a usage-specific namespace identifier
      # 
      # _@return_ — namespaced storage
      sig { params(ns: Object).returns(T::Hash[T.untyped, T.untyped]) }
      def namespace(ns); end

      sig { returns(T.untyped) }
      def inspect; end

      sig { returns(T.untyped) }
      def received_null_child; end

      # _@return_ — The target for field resolution
      sig { returns(Object) }
      def object; end

      # _@return_ — The target for field resolution
      sig { params(value: Object).returns(Object) }
      def object=(value); end

      # _@return_ — The resolved value for this field
      sig { returns(T.nilable(T.any(T::Hash[T.untyped, T.untyped], T::Array[T.untyped], String, Integer, Float, T::Boolean))) }
      def value; end

      # _@return_ — were any fields of this selection skipped?
      sig { returns(T::Boolean) }
      def skipped; end

      sig { params(value: T::Boolean).returns(T.untyped) }
      def skipped=(value); end

      # Return this value to tell the runtime
      # to exclude this field from the response altogether
      sig { returns(T.untyped) }
      def skip; end

      # _@return_ — True if this selection has been nullified by a null child
      sig { returns(T::Boolean) }
      def invalid_null?; end

      # Remove this child from the result value
      # (used for null propagation and skip)
      sig { params(child_ctx: T.untyped).returns(T.untyped) }
      def delete(child_ctx); end

      # Create a child context to use for `key`
      # 
      # _@param_ `key` — The key in the response (name or index)
      # 
      # _@param_ `irep_node` — The node being evaluated
      sig { params(key: T.any(String, Integer), irep_node: InternalRepresentation::Node, object: T.untyped).returns(T.untyped) }
      def spawn_child(key:, irep_node:, object:); end

      # Add error at query-level.
      # 
      # _@param_ `error` — an execution error
      sig { params(error: GraphQL::ExecutionError).void }
      def add_error(error); end

      # _@return_ — The backtrace for this point in query execution
      # 
      # Print the GraphQL backtrace during field resolution
      # ```ruby
      # puts ctx.backtrace
      # ```
      sig { returns(GraphQL::Backtrace) }
      def backtrace; end

      sig { returns(T.untyped) }
      def execution_errors; end

      sig { returns(T.untyped) }
      def lookahead; end

      module SharedMethods
        # _@return_ — The target for field resolution
        sig { returns(Object) }
        def object; end

        # _@return_ — The target for field resolution
        sig { params(value: Object).returns(Object) }
        def object=(value); end

        # _@return_ — The resolved value for this field
        sig { returns(T.nilable(T.any(T::Hash[T.untyped, T.untyped], T::Array[T.untyped], String, Integer, Float, T::Boolean))) }
        def value; end

        # _@return_ — were any fields of this selection skipped?
        sig { returns(T::Boolean) }
        def skipped; end

        sig { params(value: T::Boolean).returns(T.untyped) }
        def skipped=(value); end

        # Return this value to tell the runtime
        # to exclude this field from the response altogether
        sig { returns(T.untyped) }
        def skip; end

        # _@return_ — True if this selection has been nullified by a null child
        sig { returns(T::Boolean) }
        def invalid_null?; end

        # Remove this child from the result value
        # (used for null propagation and skip)
        sig { params(child_ctx: T.untyped).returns(T.untyped) }
        def delete(child_ctx); end

        # Create a child context to use for `key`
        # 
        # _@param_ `key` — The key in the response (name or index)
        # 
        # _@param_ `irep_node` — The node being evaluated
        sig { params(key: T.any(String, Integer), irep_node: InternalRepresentation::Node, object: T.untyped).returns(T.untyped) }
        def spawn_child(key:, irep_node:, object:); end

        # Add error at query-level.
        # 
        # _@param_ `error` — an execution error
        sig { params(error: GraphQL::ExecutionError).void }
        def add_error(error); end

        # _@return_ — The backtrace for this point in query execution
        # 
        # Print the GraphQL backtrace during field resolution
        # ```ruby
        # puts ctx.backtrace
        # ```
        sig { returns(GraphQL::Backtrace) }
        def backtrace; end

        sig { returns(T.untyped) }
        def execution_errors; end

        sig { returns(T.untyped) }
        def lookahead; end
      end

      class ExecutionErrors
        sig { params(ctx: T.untyped).returns(ExecutionErrors) }
        def initialize(ctx); end

        sig { params(err_or_msg: T.untyped).returns(T.untyped) }
        def add(err_or_msg); end
      end

      class FieldResolutionContext
        include GraphQL::Query::Context::SharedMethods
        include GraphQL::Tracing::Traceable
        extend Forwardable

        # Returns the value of attribute irep_node
        sig { returns(T.untyped) }
        def irep_node; end

        # Returns the value of attribute field
        sig { returns(T.untyped) }
        def field; end

        # Returns the value of attribute parent_type
        sig { returns(T.untyped) }
        def parent_type; end

        # Returns the value of attribute query
        sig { returns(T.untyped) }
        def query; end

        # Returns the value of attribute schema
        sig { returns(T.untyped) }
        def schema; end

        # Returns the value of attribute parent
        sig { returns(T.untyped) }
        def parent; end

        # Returns the value of attribute key
        sig { returns(T.untyped) }
        def key; end

        # Returns the value of attribute type
        sig { returns(T.untyped) }
        def type; end

        sig do
          params(
            context: T.untyped,
            key: T.untyped,
            irep_node: T.untyped,
            parent: T.untyped,
            object: T.untyped
          ).returns(FieldResolutionContext)
        end
        def initialize(context, key, irep_node, parent, object); end

        sig { returns(T.untyped) }
        def wrapped_connection; end

        sig { params(value: T.untyped).returns(T.untyped) }
        def wrapped_connection=(value); end

        sig { returns(T.untyped) }
        def wrapped_object; end

        sig { params(value: T.untyped).returns(T.untyped) }
        def wrapped_object=(value); end

        sig { returns(T.untyped) }
        def path; end

        # _@return_ — The AST node for the currently-executing field
        sig { returns(GraphQL::Language::Nodes::Field) }
        def ast_node; end

        # Add error to current field resolution.
        # 
        # _@param_ `error` — an execution error
        sig { params(error: GraphQL::ExecutionError).void }
        def add_error(error); end

        sig { returns(T.untyped) }
        def inspect; end

        # Set a new value for this field in the response.
        # It may be updated after resolving a {Lazy}.
        # If it is {Execute::PROPAGATE_NULL}, tell the owner to propagate null.
        # If it's {Execute::Execution::SKIP}, remove this field result from its parent
        # 
        # _@param_ `new_value` — The GraphQL-ready value
        sig { params(new_value: T.untyped).returns(T.untyped) }
        def value=(new_value); end

        sig { returns(T.untyped) }
        def received_null_child; end

        sig { params(type: T.untyped).returns(T::Boolean) }
        def list_of_non_null_items?(type); end

        # _@param_ `key` — The name of the event in GraphQL internals
        # 
        # _@param_ `metadata` — Event-related metadata (can be anything)
        # 
        # _@return_ — Must return the value of the block
        sig { params(key: String, metadata: T::Hash[T.untyped, T.untyped]).returns(Object) }
        def trace(key, metadata); end

        # If there's a tracer at `idx`, call it and then increment `idx`.
        # Otherwise, yield.
        # 
        # _@param_ `idx` — Which tracer to call
        # 
        # _@param_ `key` — The current event name
        # 
        # _@param_ `metadata` — The current event object
        # 
        # _@return_ — Whatever the block returns
        sig { params(idx: Integer, key: String, metadata: Object).returns(T.untyped) }
        def call_tracers(idx, key, metadata); end

        # _@return_ — The target for field resolution
        sig { returns(Object) }
        def object; end

        # _@return_ — The target for field resolution
        sig { params(value: Object).returns(Object) }
        def object=(value); end

        # _@return_ — The resolved value for this field
        sig { returns(T.nilable(T.any(T::Hash[T.untyped, T.untyped], T::Array[T.untyped], String, Integer, Float, T::Boolean))) }
        def value; end

        # _@return_ — were any fields of this selection skipped?
        sig { returns(T::Boolean) }
        def skipped; end

        sig { params(value: T::Boolean).returns(T.untyped) }
        def skipped=(value); end

        # Return this value to tell the runtime
        # to exclude this field from the response altogether
        sig { returns(T.untyped) }
        def skip; end

        # _@return_ — True if this selection has been nullified by a null child
        sig { returns(T::Boolean) }
        def invalid_null?; end

        # Remove this child from the result value
        # (used for null propagation and skip)
        sig { params(child_ctx: T.untyped).returns(T.untyped) }
        def delete(child_ctx); end

        # Create a child context to use for `key`
        # 
        # _@param_ `key` — The key in the response (name or index)
        # 
        # _@param_ `irep_node` — The node being evaluated
        sig { params(key: T.any(String, Integer), irep_node: InternalRepresentation::Node, object: T.untyped).returns(T.untyped) }
        def spawn_child(key:, irep_node:, object:); end

        # _@return_ — The backtrace for this point in query execution
        # 
        # Print the GraphQL backtrace during field resolution
        # ```ruby
        # puts ctx.backtrace
        # ```
        sig { returns(GraphQL::Backtrace) }
        def backtrace; end

        sig { returns(T.untyped) }
        def execution_errors; end

        sig { returns(T.untyped) }
        def lookahead; end
      end
    end

    class Executor
      # _@return_ — the query being executed
      sig { returns(GraphQL::Query) }
      def query; end

      sig { params(query: T.untyped).returns(Executor) }
      def initialize(query); end

      # Evaluate {operation_name} on {query}.
      # Handle {GraphQL::ExecutionError}s by putting them in the "errors" key.
      # 
      # _@return_ — A GraphQL response, with either a "data" key or an "errors" key
      sig { returns(T::Hash[T.untyped, T.untyped]) }
      def result; end

      sig { returns(T.untyped) }
      def execute; end

      class PropagateNull < StandardError
      end
    end

    # Read-only access to values, normalizing all keys to strings
    # 
    # {Arguments} recursively wraps the input in {Arguments} instances.
    class Arguments
      include GraphQL::Dig
      extend Forwardable
      NO_ARGS = T.let(NoArguments.new({}, context: nil, defaults_used: Set.new), T.untyped)
      NULL_ARGUMENT_VALUE = T.let(ArgumentValue.new(nil, nil, nil, nil), T.untyped)

      sig { params(argument_owner: T.untyped).returns(T.untyped) }
      def self.construct_arguments_class(argument_owner); end

      # Returns the value of attribute argument_values
      sig { returns(T.untyped) }
      def argument_values; end

      sig { params(values: T.untyped, context: T.untyped, defaults_used: T.untyped).returns(Arguments) }
      def initialize(values, context:, defaults_used:); end

      # _@param_ `key` — name or index of value to access
      # 
      # _@return_ — the argument at that key
      sig { params(key: T.any(String, Symbol)).returns(Object) }
      def [](key); end

      # _@param_ `key` — name of value to access
      # 
      # _@return_ — true if the argument was present in this field
      sig { params(key: T.any(String, Symbol)).returns(T::Boolean) }
      def key?(key); end

      # _@param_ `key` — name of value to access
      # 
      # _@return_ — true if the argument default was passed as the argument value to the resolver
      sig { params(key: T.any(String, Symbol)).returns(T::Boolean) }
      def default_used?(key); end

      # Get the hash of all values, with stringified keys
      # 
      # _@return_ — the stringified hash
      sig { returns(T::Hash[T.untyped, T.untyped]) }
      def to_h; end

      # Access each key, value and type for the arguments in this set.
      sig { returns(T.untyped) }
      def each_value; end

      # Returns the value of attribute argument_definitions
      sig { returns(T.untyped) }
      def self.argument_definitions; end

      # Sets the attribute argument_definitions
      # 
      # _@param_ `value` — the value to set the attribute argument_definitions to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self.argument_definitions=(value); end

      # Returns the value of attribute argument_owner
      sig { returns(T.untyped) }
      def self.argument_owner; end

      # Sets the attribute argument_owner
      # 
      # _@param_ `value` — the value to set the attribute argument_owner to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self.argument_owner=(value); end

      # Convert this instance into valid Ruby keyword arguments
      sig { returns(T::Hash[Symbol, Object]) }
      def to_kwargs; end

      sig { params(value: T.untyped, arg_defn_type: T.untyped, context: T.untyped).returns(T.untyped) }
      def wrap_value(value, arg_defn_type, context); end

      sig { params(value: T.untyped).returns(T.untyped) }
      def unwrap_value(value); end

      # implemented using the old activesupport #dig instead of the ruby built-in
      # so we can use some of the magic in Schema::InputObject and Query::Arguments
      # to handle stringified/symbolized keys.
      # 
      # _@param_ `args` — rgs [Array<[String, Symbol>] Retrieves the value object corresponding to the each key objects repeatedly
      sig { params(own_key: T.untyped, rest_keys: T.untyped).returns(Object) }
      def dig(own_key, *rest_keys); end

      class ArgumentValue
        # Returns the value of attribute key
        sig { returns(T.untyped) }
        def key; end

        # Returns the value of attribute value
        sig { returns(T.untyped) }
        def value; end

        # Returns the value of attribute definition
        sig { returns(T.untyped) }
        def definition; end

        # Sets the attribute default_used
        # 
        # _@param_ `value` — the value to set the attribute default_used to.
        sig { params(value: T.untyped).returns(T.untyped) }
        def default_used=(value); end

        sig do
          params(
            key: T.untyped,
            value: T.untyped,
            definition: T.untyped,
            default_used: T.untyped
          ).returns(ArgumentValue)
        end
        def initialize(key, value, definition, default_used); end

        # _@return_ — true if the argument default was passed as the argument value to the resolver
        sig { returns(T::Boolean) }
        def default_used?; end
      end
    end

    # Read-only access to query variables, applying default values if needed.
    class Variables
      extend Forwardable

      # _@return_ — Any errors encountered when parsing the provided variables and literal values
      sig { returns(T::Array[GraphQL::Query::VariableValidationError]) }
      def errors; end

      # Returns the value of attribute context
      sig { returns(T.untyped) }
      def context; end

      sig { params(ctx: T.untyped, ast_variables: T.untyped, provided_variables: T.untyped).returns(Variables) }
      def initialize(ctx, ast_variables, provided_variables); end
    end

    # This object can be `ctx` in places where there is no query
    class NullContext
      extend Forwardable

      # Returns the value of attribute schema
      sig { returns(T.untyped) }
      def schema; end

      # Returns the value of attribute query
      sig { returns(T.untyped) }
      def query; end

      # Returns the value of attribute warden
      sig { returns(T.untyped) }
      def warden; end

      sig { returns(NullContext) }
      def initialize; end

      sig { returns(T.untyped) }
      def self.instance; end

      class NullWarden < GraphQL::Schema::Warden
        sig { params(t: T.untyped).returns(T::Boolean) }
        def visible?(t); end

        sig { params(t: T.untyped).returns(T::Boolean) }
        def visible_field?(t); end

        sig { params(t: T.untyped).returns(T::Boolean) }
        def visible_type?(t); end
      end
    end

    # Turn query string values into something useful for query execution
    class LiteralInput
      sig { params(type: T.untyped, ast_node: T.untyped, variables: T.untyped).returns(T.untyped) }
      def self.coerce(type, ast_node, variables); end

      sig { params(ast_arguments: T.untyped, argument_owner: T.untyped, variables: T.untyped).returns(T.untyped) }
      def self.from_arguments(ast_arguments, argument_owner, variables); end
    end

    module ArgumentsCache
      sig { params(query: T.untyped).returns(T.untyped) }
      def self.build(query); end
    end

    class SerialExecution
      # This is the only required method for an Execution strategy.
      # You could create a custom execution strategy and configure your schema to
      # use that custom strategy instead.
      # 
      # _@param_ `ast_operation` — The operation definition to run
      # 
      # _@param_ `root_type` — either the query type or the mutation type
      # 
      # _@param_ `query_object` — the query object for this execution
      # 
      # _@return_ — a spec-compliant GraphQL result, as a hash
      sig { params(ast_operation: GraphQL::Language::Nodes::OperationDefinition, root_type: GraphQL::ObjectType, query_object: GraphQL::Query).returns(T::Hash[T.untyped, T.untyped]) }
      def execute(ast_operation, root_type, query_object); end

      sig { returns(T.untyped) }
      def field_resolution; end

      sig { returns(T.untyped) }
      def operation_resolution; end

      sig { returns(T.untyped) }
      def selection_resolution; end

      class FieldResolution
        # Returns the value of attribute irep_node
        sig { returns(T.untyped) }
        def irep_node; end

        # Returns the value of attribute parent_type
        sig { returns(T.untyped) }
        def parent_type; end

        # Returns the value of attribute target
        sig { returns(T.untyped) }
        def target; end

        # Returns the value of attribute field
        sig { returns(T.untyped) }
        def field; end

        # Returns the value of attribute arguments
        sig { returns(T.untyped) }
        def arguments; end

        # Returns the value of attribute query
        sig { returns(T.untyped) }
        def query; end

        sig do
          params(
            selection: T.untyped,
            parent_type: T.untyped,
            target: T.untyped,
            query_ctx: T.untyped
          ).returns(FieldResolution)
        end
        def initialize(selection, parent_type, target, query_ctx); end

        sig { returns(T.untyped) }
        def result; end

        # GraphQL::Batch depends on this
        sig { returns(T.untyped) }
        def execution_context; end

        # After getting the value from the field's resolve method,
        # continue by "finishing" the value, eg. executing sub-fields or coercing values
        sig { params(raw_value: T.untyped).returns(T.untyped) }
        def get_finished_value(raw_value); end

        # Get the result of:
        # - Any middleware on this schema
        # - The field's resolve method
        # If the middleware chain returns a GraphQL::ExecutionError, its message
        # is added to the "errors" key.
        sig { returns(T.untyped) }
        def get_raw_value; end
      end

      module ValueResolution
        sig do
          params(
            parent_type: T.untyped,
            field_defn: T.untyped,
            field_type: T.untyped,
            value: T.untyped,
            selection: T.untyped,
            query_ctx: T.untyped
          ).returns(T.untyped)
        end
        def self.resolve(parent_type, field_defn, field_type, value, selection, query_ctx); end
      end

      module OperationResolution
        sig { params(selection: T.untyped, target: T.untyped, query: T.untyped).returns(T.untyped) }
        def self.resolve(selection, target, query); end
      end

      module SelectionResolution
        sig do
          params(
            target: T.untyped,
            current_type: T.untyped,
            selection: T.untyped,
            query_ctx: T.untyped
          ).returns(T.untyped)
        end
        def self.resolve(target, current_type, selection, query_ctx); end
      end
    end

    # Contain the validation pipeline and expose the results.
    # 
    # 0. Checks in {Query#initialize}:
    #   - Rescue a ParseError, halt if there is one
    #   - Check for selected operation, halt if not found
    # 1. Validate the AST, halt if errors
    # 2. Validate the variables, halt if errors
    # 3. Run query analyzers, halt if errors
    # 
    # {#valid?} is false if any of the above checks halted the pipeline.
    # 
    # @api private
    class ValidationPipeline
      sig { returns(T.untyped) }
      def max_depth; end

      sig { returns(T.untyped) }
      def max_complexity; end

      sig do
        params(
          query: T.untyped,
          validate: T.untyped,
          parse_error: T.untyped,
          operation_name_error: T.untyped,
          max_depth: T.untyped,
          max_complexity: T.untyped
        ).returns(ValidationPipeline)
      end
      def initialize(query:, validate:, parse_error:, operation_name_error:, max_depth:, max_complexity:); end

      # _@return_ — does this query have errors that should prevent it from running?
      sig { returns(T::Boolean) }
      def valid?; end

      # _@return_ — Static validation errors for the query string
      sig { returns(T::Array[GraphQL::StaticValidation::Error]) }
      def validation_errors; end

      # _@return_ — Irep node pairs
      sig { returns(T.untyped) }
      def internal_representation; end

      sig { returns(T.untyped) }
      def analyzers; end

      # If the pipeline wasn't run yet, run it.
      # If it was already run, do nothing.
      sig { returns(T.untyped) }
      def ensure_has_validated; end

      # If there are max_* values, add them,
      # otherwise reuse the schema's list of analyzers.
      sig { params(schema: T.untyped, max_depth: T.untyped, max_complexity: T.untyped).returns(T.untyped) }
      def build_analyzers(schema, max_depth, max_complexity); end
    end

    class InputValidationResult
      # Returns the value of attribute problems
      sig { returns(T.untyped) }
      def problems; end

      # Sets the attribute problems
      # 
      # _@param_ `value` — the value to set the attribute problems to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def problems=(value); end

      sig { returns(T::Boolean) }
      def valid?; end

      sig { params(explanation: T.untyped, path: T.untyped).returns(T.untyped) }
      def add_problem(explanation, path = nil); end

      sig { params(path: T.untyped, inner_result: T.untyped).returns(T.untyped) }
      def merge_result!(path, inner_result); end
    end

    class VariableValidationError < GraphQL::ExecutionError
      # Returns the value of attribute value
      sig { returns(T.untyped) }
      def value; end

      # Sets the attribute value
      # 
      # _@param_ `value` — the value to set the attribute value to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def value=(value); end

      # Returns the value of attribute validation_result
      sig { returns(T.untyped) }
      def validation_result; end

      # Sets the attribute validation_result
      # 
      # _@param_ `value` — the value to set the attribute validation_result to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def validation_result=(value); end

      sig do
        params(
          variable_ast: T.untyped,
          type: T.untyped,
          value: T.untyped,
          validation_result: T.untyped
        ).returns(VariableValidationError)
      end
      def initialize(variable_ast, type, value, validation_result); end

      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def problem_fields; end
    end
  end

  module Define
    # A helper for definitions that store their value in `#metadata`.
    # 
    # _@param_ `key` — the key to assign in metadata
    # 
    # _@return_ — an assignment for `.accepts_definitions` which writes `key` to `#metadata`
    # 
    # Storing application classes with GraphQL types
    # ```ruby
    # # Make a custom definition
    # GraphQL::ObjectType.accepts_definitions(resolves_to_class_names: GraphQL::Define.assign_metadata_key(:resolves_to_class_names))
    # 
    # # After definition, read the key from metadata
    # PostType.metadata[:resolves_to_class_names] # => [...]
    # ```
    sig { params(key: Object).returns(T.untyped) }
    def self.assign_metadata_key(key); end

    # Some conveniences for definining return & argument types.
    # 
    # Passed into initialization blocks, eg {ObjectType#initialize}, {Field#initialize}
    class TypeDefiner
      include Singleton

      # rubocop:disable Naming/MethodName
      sig { returns(T.untyped) }
      def Int; end

      sig { returns(T.untyped) }
      def String; end

      sig { returns(T.untyped) }
      def Float; end

      sig { returns(T.untyped) }
      def Boolean; end

      sig { returns(T.untyped) }
      def ID; end

      # Make a {ListType} which wraps the input type
      # 
      # _@param_ `type` — A type to be wrapped in a ListType
      # 
      # _@return_ — A ListType wrapping `type`
      # 
      # making a list type
      # ```ruby
      # list_of_strings = types[types.String]
      # list_of_strings.inspect
      # # => "[String]"
      # ```
      sig { params(type: T.untyped).returns(GraphQL::ListType) }
      def [](type); end
    end

    # Turn argument configs into a {GraphQL::Argument}.
    module AssignArgument
      sig do
        params(
          target: T.untyped,
          args: T.untyped,
          kwargs: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def self.call(target, *args, **kwargs, &block); end
    end

    module AssignConnection
      sig do
        params(
          type_defn: T.untyped,
          field_args: T.untyped,
          max_page_size: T.untyped,
          field_kwargs: T.untyped,
          field_block: T.untyped
        ).returns(T.untyped)
      end
      def self.call(type_defn, *field_args, max_page_size: nil, **field_kwargs, &field_block); end
    end

    # Turn enum value configs into a {GraphQL::EnumType::EnumValue} and register it with the {GraphQL::EnumType}
    module AssignEnumValue
      sig do
        params(
          enum_type: T.untyped,
          name: T.untyped,
          desc: T.untyped,
          deprecation_reason: T.untyped,
          value: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def self.call(enum_type, name, desc = nil, deprecation_reason: nil, value: name, &block); end
    end

    # This module provides the `.define { ... }` API for
    # {GraphQL::BaseType}, {GraphQL::Field} and others.
    # 
    # Calling `.accepts_definitions(...)` creates:
    # 
    # - a keyword to the `.define` method
    # - a helper method in the `.define { ... }` block
    # 
    # The `.define { ... }` block will be called lazily. To be sure it has been
    # called, use the private method `#ensure_defined`. That will call the
    # definition block if it hasn't been called already.
    # 
    # The goals are:
    # 
    # - Minimal overhead in consuming classes
    # - Independence between consuming classes
    # - Extendable by third-party libraries without monkey-patching or other nastiness
    # 
    # @example Make a class definable
    #   class Car
    #     include GraphQL::Define::InstanceDefinable
    #     attr_accessor :make, :model, :doors
    #     accepts_definitions(
    #       # These attrs will be defined with plain setters, `{attr}=`
    #       :make, :model,
    #       # This attr has a custom definition which applies the config to the target
    #       doors: ->(car, doors_count) { doors_count.times { car.doors << Door.new } }
    #     )
    #     ensure_defined(:make, :model, :doors)
    # 
    #     def initialize
    #       @doors = []
    #     end
    #   end
    # 
    #   class Door; end;
    # 
    #   # Create an instance with `.define`:
    #   subaru_baja = Car.define do
    #     make "Subaru"
    #     model "Baja"
    #     doors 4
    #   end
    # 
    #   # The custom proc was applied:
    #   subaru_baja.doors #=> [<Door>, <Door>, <Door>, <Door>]
    # 
    # @example Extending the definition of a class
    #   # Add some definitions:
    #   Car.accepts_definitions(all_wheel_drive: GraphQL::Define.assign_metadata_key(:all_wheel_drive))
    # 
    #   # Use it in a definition
    #   subaru_baja = Car.define do
    #     # ...
    #     all_wheel_drive true
    #   end
    # 
    #   # Access it from metadata
    #   subaru_baja.metadata[:all_wheel_drive] # => true
    # 
    # @example Extending the definition of a class via a plugin
    #   # A plugin is any object that responds to `.use(definition)`
    #   module SubaruCar
    #     extend self
    # 
    #     def use(defn)
    #       # `defn` has the same methods as within `.define { ... }` block
    #       defn.make "Subaru"
    #       defn.doors 4
    #     end
    #   end
    # 
    #   # Use the plugin within a `.define { ... }` block
    #   subaru_baja = Car.define do
    #     use SubaruCar
    #     model 'Baja'
    #   end
    # 
    #   subaru_baja.make # => "Subaru"
    #   subaru_baja.doors # => [<Door>, <Door>, <Door>, <Door>]
    # 
    # @example Making a copy with an extended definition
    #   # Create an instance with `.define`:
    #   subaru_baja = Car.define do
    #     make "Subaru"
    #     model "Baja"
    #     doors 4
    #   end
    # 
    #   # Then extend it with `#redefine`
    #   two_door_baja = subaru_baja.redefine do
    #     doors 2
    #   end
    module InstanceDefinable
      sig { params(base: T.untyped).returns(T.untyped) }
      def self.included(base); end

      # `metadata` can store arbitrary key-values with an object.
      # 
      # _@return_ — Hash for user-defined storage
      sig { returns(T::Hash[Object, Object]) }
      def metadata; end

      # Mutate this instance using functions from its {.definition}s.
      # Keywords or helpers in the block correspond to keys given to `accepts_definitions`.
      # 
      # Note that the block is not called right away -- instead, it's deferred until
      # one of the defined fields is needed.
      sig { params(kwargs: T.untyped, block: T.untyped).void }
      def define(**kwargs, &block); end

      # Shallow-copy this object, then apply new definitions to the copy.
      # 
      # _@return_ — A new instance, with any extended definitions
      # 
      # _@see_ `{#define}` — for arguments
      sig { params(kwargs: T.untyped, block: T.untyped).returns(InstanceDefinable) }
      def redefine(**kwargs, &block); end

      sig { params(other: T.untyped).returns(T.untyped) }
      def initialize_copy(other); end

      # Run the definition block if it hasn't been run yet.
      # This can only be run once: the block is deleted after it's used.
      # You have to call this before using any value which could
      # come from the definition block.
      sig { void }
      def ensure_defined; end

      # Take the pending methods and put them back on this object's singleton class.
      # This reverts the process done by {#stash_dependent_methods}
      sig { void }
      def revive_dependent_methods; end

      # Find the method names which were declared as definition-dependent,
      # then grab the method definitions off of this object's class
      # and store them for later.
      # 
      # Then make a dummy method for each of those method names which:
      # 
      # - Triggers the pending definition, if there is one
      # - Calls the same method again.
      # 
      # It's assumed that {#ensure_defined} will put the original method definitions
      # back in place with {#revive_dependent_methods}.
      sig { void }
      def stash_dependent_methods; end

      class Definition
        # Returns the value of attribute define_keywords
        sig { returns(T.untyped) }
        def define_keywords; end

        # Returns the value of attribute define_proc
        sig { returns(T.untyped) }
        def define_proc; end

        sig { params(define_keywords: T.untyped, define_proc: T.untyped).returns(Definition) }
        def initialize(define_keywords, define_proc); end
      end

      module ClassMethods
        # Create a new instance
        # and prepare a definition using its {.definitions}.
        # 
        # _@param_ `kwargs` — Key-value pairs corresponding to defininitions from `accepts_definitions`
        # 
        # _@param_ `block` — Block which calls helper methods from `accepts_definitions`
        sig { params(kwargs: T::Hash[T.untyped, T.untyped], block: T.untyped).returns(T.untyped) }
        def define(**kwargs, &block); end

        # Attach definitions to this class.
        # Each symbol in `accepts` will be assigned with `{key}=`.
        # The last entry in accepts may be a hash of name-proc pairs for custom definitions.
        sig { params(accepts: T.untyped).returns(T.untyped) }
        def accepts_definitions(*accepts); end

        sig { params(method_names: T.untyped).returns(T.untyped) }
        def ensure_defined(*method_names); end

        sig { returns(T.untyped) }
        def ensure_defined_method_names; end

        # _@return_ — combined definitions for self and ancestors
        sig { returns(T::Hash[T.untyped, T.untyped]) }
        def dictionary; end

        # _@return_ — definitions for this class only
        sig { returns(T::Hash[T.untyped, T.untyped]) }
        def own_dictionary; end
      end

      class AssignMetadataKey
        sig { params(key: T.untyped).returns(AssignMetadataKey) }
        def initialize(key); end

        sig { params(defn: T.untyped, value: T.untyped).returns(T.untyped) }
        def call(defn, value = true); end
      end

      class AssignAttribute
        sig { params(attr_name: T.untyped).returns(AssignAttribute) }
        def initialize(attr_name); end

        sig { params(defn: T.untyped, value: T.untyped).returns(T.untyped) }
        def call(defn, value); end
      end
    end

    # Wrap the object in NonNullType in response to `!`
    # @example required Int type
    #   !GraphQL::INT_TYPE
    module NonNullWithBang
      # Make the type non-null
      # 
      # _@return_ — a non-null type which wraps the original type
      sig { returns(GraphQL::NonNullType) }
      def !; end
    end

    # Turn field configs into a {GraphQL::Field} and attach it to a {GraphQL::ObjectType} or {GraphQL::InterfaceType}
    module AssignObjectField
      sig do
        params(
          owner_type: T.untyped,
          name: T.untyped,
          type_or_field: T.untyped,
          desc: T.untyped,
          function: T.untyped,
          field: T.untyped,
          relay_mutation_function: T.untyped,
          kwargs: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def self.call(owner_type, name, type_or_field = nil, desc = nil, function: nil, field: nil, relay_mutation_function: nil, **kwargs, &block); end
    end

    class NoDefinitionError < GraphQL::Error
    end

    # This object delegates most methods to a dictionary of functions, {@dictionary}.
    # {@target} is passed to the specified function, along with any arguments and block.
    # This allows a method-based DSL without adding methods to the defined class.
    class DefinedObjectProxy
      # The object which will be defined by definition functions
      sig { returns(T.untyped) }
      def target; end

      sig { params(target: T.untyped).returns(DefinedObjectProxy) }
      def initialize(target); end

      # Provides shorthand access to GraphQL's built-in types
      sig { returns(T.untyped) }
      def types; end

      # Allow `plugin` to perform complex initialization on the definition.
      # Calls `plugin.use(defn, **kwargs)`.
      # 
      # _@param_ `plugin` — A plugin object
      # 
      # _@param_ `kwargs` — Any options for the plugin
      sig { params(plugin: T::Array[T.untyped], kwargs: T::Hash[T.untyped, T.untyped]).returns(T.untyped) }
      def use(plugin, **kwargs); end

      # Lookup a function from the dictionary and call it if it's found.
      sig { params(name: T.untyped, args: T.untyped, block: T.untyped).returns(T.untyped) }
      def method_missing(name, *args, &block); end

      sig { params(name: T.untyped, include_private: T.untyped).returns(T::Boolean) }
      def respond_to_missing?(name, include_private = false); end
    end

    module AssignGlobalIdField
      sig { params(type_defn: T.untyped, field_name: T.untyped).returns(T.untyped) }
      def self.call(type_defn, field_name); end
    end

    module AssignMutationFunction
      sig { params(target: T.untyped, function: T.untyped).returns(T.untyped) }
      def self.call(target, function); end

      class ResultProxy < SimpleDelegator
        # Returns the value of attribute client_mutation_id
        sig { returns(T.untyped) }
        def client_mutation_id; end

        sig { params(target: T.untyped, client_mutation_id: T.untyped).returns(ResultProxy) }
        def initialize(target, client_mutation_id); end
      end
    end
  end

  # @api private
  class Filter
    sig { params(only: T.untyped, except: T.untyped).returns(Filter) }
    def initialize(only: nil, except: nil); end

    # Returns true if `member, ctx` passes this filter
    sig { params(member: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def call(member, ctx); end

    sig { params(only: T.untyped, except: T.untyped).returns(T.untyped) }
    def merge(only: nil, except: nil); end

    class MergedOnly
      sig { params(first: T.untyped, second: T.untyped).returns(MergedOnly) }
      def initialize(first, second); end

      sig { params(member: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def call(member, ctx); end

      sig { params(onlies: T.untyped).returns(T.untyped) }
      def self.build(onlies); end
    end

    class MergedExcept < GraphQL::Filter::MergedOnly
      sig { params(member: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def call(member, ctx); end
    end
  end

  # Extend this class to define GraphQL enums in your schema.
  # 
  # By default, GraphQL enum values are translated into Ruby strings.
  # You can provide a custom value with the `value:` keyword.
  # 
  # @example
  #   # equivalent to
  #   # enum PizzaTopping {
  #   #   MUSHROOMS
  #   #   ONIONS
  #   #   PEPPERS
  #   # }
  #   class PizzaTopping < GraphQL::Enum
  #     value :MUSHROOMS
  #     value :ONIONS
  #     value :PEPPERS
  #   end
  class Schema
    include GraphQL::Define::InstanceDefinable
    extend Forwardable
    extend GraphQL::Schema::Member::AcceptsDefinition
    extend GraphQL::Schema::Member::HasAstNode
    extend GraphQL::Schema::FindInheritedValue
    DYNAMIC_FIELDS = T.let(["__type", "__typename", "__schema"].freeze, T.untyped)
    Context = T.let(GraphQL::Query::Context, T.untyped)
    BUILT_IN_TYPES = T.let({
  "Int" => INT_TYPE,
  "String" => STRING_TYPE,
  "Float" => FLOAT_TYPE,
  "Boolean" => BOOLEAN_TYPE,
  "ID" => ID_TYPE,
}, T.untyped)

    # Returns the value of attribute query
    sig { returns(T.untyped) }
    def query; end

    # Sets the attribute query
    # 
    # _@param_ `value` — the value to set the attribute query to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def query=(value); end

    # Returns the value of attribute mutation
    sig { returns(T.untyped) }
    def mutation; end

    # Sets the attribute mutation
    # 
    # _@param_ `value` — the value to set the attribute mutation to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def mutation=(value); end

    # Returns the value of attribute subscription
    sig { returns(T.untyped) }
    def subscription; end

    # Sets the attribute subscription
    # 
    # _@param_ `value` — the value to set the attribute subscription to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def subscription=(value); end

    # Returns the value of attribute query_execution_strategy
    sig { returns(T.untyped) }
    def query_execution_strategy; end

    # Sets the attribute query_execution_strategy
    # 
    # _@param_ `value` — the value to set the attribute query_execution_strategy to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def query_execution_strategy=(value); end

    # Returns the value of attribute mutation_execution_strategy
    sig { returns(T.untyped) }
    def mutation_execution_strategy; end

    # Sets the attribute mutation_execution_strategy
    # 
    # _@param_ `value` — the value to set the attribute mutation_execution_strategy to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def mutation_execution_strategy=(value); end

    # Returns the value of attribute subscription_execution_strategy
    sig { returns(T.untyped) }
    def subscription_execution_strategy; end

    # Sets the attribute subscription_execution_strategy
    # 
    # _@param_ `value` — the value to set the attribute subscription_execution_strategy to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def subscription_execution_strategy=(value); end

    # Returns the value of attribute max_depth
    sig { returns(T.untyped) }
    def max_depth; end

    # Sets the attribute max_depth
    # 
    # _@param_ `value` — the value to set the attribute max_depth to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def max_depth=(value); end

    # Returns the value of attribute max_complexity
    sig { returns(T.untyped) }
    def max_complexity; end

    # Sets the attribute max_complexity
    # 
    # _@param_ `value` — the value to set the attribute max_complexity to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def max_complexity=(value); end

    # Returns the value of attribute default_max_page_size
    sig { returns(T.untyped) }
    def default_max_page_size; end

    # Sets the attribute default_max_page_size
    # 
    # _@param_ `value` — the value to set the attribute default_max_page_size to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def default_max_page_size=(value); end

    # Returns the value of attribute orphan_types
    sig { returns(T.untyped) }
    def orphan_types; end

    # Sets the attribute orphan_types
    # 
    # _@param_ `value` — the value to set the attribute orphan_types to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def orphan_types=(value); end

    # Returns the value of attribute directives
    sig { returns(T.untyped) }
    def directives; end

    # Sets the attribute directives
    # 
    # _@param_ `value` — the value to set the attribute directives to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def directives=(value); end

    # Returns the value of attribute query_analyzers
    sig { returns(T.untyped) }
    def query_analyzers; end

    # Sets the attribute query_analyzers
    # 
    # _@param_ `value` — the value to set the attribute query_analyzers to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def query_analyzers=(value); end

    # Returns the value of attribute multiplex_analyzers
    sig { returns(T.untyped) }
    def multiplex_analyzers; end

    # Sets the attribute multiplex_analyzers
    # 
    # _@param_ `value` — the value to set the attribute multiplex_analyzers to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def multiplex_analyzers=(value); end

    # Returns the value of attribute instrumenters
    sig { returns(T.untyped) }
    def instrumenters; end

    # Sets the attribute instrumenters
    # 
    # _@param_ `value` — the value to set the attribute instrumenters to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def instrumenters=(value); end

    # Returns the value of attribute lazy_methods
    sig { returns(T.untyped) }
    def lazy_methods; end

    # Sets the attribute lazy_methods
    # 
    # _@param_ `value` — the value to set the attribute lazy_methods to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def lazy_methods=(value); end

    # Returns the value of attribute cursor_encoder
    sig { returns(T.untyped) }
    def cursor_encoder; end

    # Sets the attribute cursor_encoder
    # 
    # _@param_ `value` — the value to set the attribute cursor_encoder to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def cursor_encoder=(value); end

    # Returns the value of attribute ast_node
    sig { returns(T.untyped) }
    def ast_node; end

    # Sets the attribute ast_node
    # 
    # _@param_ `value` — the value to set the attribute ast_node to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def ast_node=(value); end

    # Returns the value of attribute raise_definition_error
    sig { returns(T.untyped) }
    def raise_definition_error; end

    # Sets the attribute raise_definition_error
    # 
    # _@param_ `value` — the value to set the attribute raise_definition_error to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def raise_definition_error=(value); end

    # Returns the value of attribute introspection_namespace
    sig { returns(T.untyped) }
    def introspection_namespace; end

    # Sets the attribute introspection_namespace
    # 
    # _@param_ `value` — the value to set the attribute introspection_namespace to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def introspection_namespace=(value); end

    # Returns the value of attribute analysis_engine
    sig { returns(T.untyped) }
    def analysis_engine; end

    # Sets the attribute analysis_engine
    # 
    # _@param_ `value` — the value to set the attribute analysis_engine to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def analysis_engine=(value); end

    # [Boolean] True if this object bubbles validation errors up from a field into its parent InputObject, if there is one.
    sig { returns(T.untyped) }
    def error_bubbling; end

    # [Boolean] True if this object bubbles validation errors up from a field into its parent InputObject, if there is one.
    sig { params(value: T.untyped).returns(T.untyped) }
    def error_bubbling=(value); end

    # Single, long-lived instance of the provided subscriptions class, if there is one.
    sig { returns(GraphQL::Subscriptions) }
    def subscriptions; end

    # Single, long-lived instance of the provided subscriptions class, if there is one.
    sig { params(value: GraphQL::Subscriptions).returns(GraphQL::Subscriptions) }
    def subscriptions=(value); end

    # _@return_ — MiddlewareChain which is applied to fields during execution
    sig { returns(MiddlewareChain) }
    def middleware; end

    # _@return_ — MiddlewareChain which is applied to fields during execution
    sig { params(value: MiddlewareChain).returns(MiddlewareChain) }
    def middleware=(value); end

    # _@return_ — A callable for filtering members of the schema
    # 
    # _@see_ `{Query.new}` — for query-specific filters with `except:`
    sig { returns(T::Array[T.untyped]) }
    def default_mask; end

    # _@return_ — A callable for filtering members of the schema
    # 
    # _@see_ `{Query.new}` — for query-specific filters with `except:`
    sig { params(value: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
    def default_mask=(value); end

    # _@return_ — Instantiated for each query
    # 
    # _@see_ `{GraphQL::Query::Context}` — The parent class of these classes
    sig { returns(Class) }
    def context_class; end

    # _@return_ — Instantiated for each query
    # 
    # _@see_ `{GraphQL::Query::Context}` — The parent class of these classes
    sig { params(value: Class).returns(Class) }
    def context_class=(value); end

    # [Boolean] True if this object disables the introspection entry point fields
    sig { returns(T.untyped) }
    def disable_introspection_entry_points; end

    # [Boolean] True if this object disables the introspection entry point fields
    sig { params(value: T.untyped).returns(T.untyped) }
    def disable_introspection_entry_points=(value); end

    # Sets the attribute default_execution_strategy
    # 
    # _@param_ `value` — the value to set the attribute default_execution_strategy to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def self.default_execution_strategy=(value); end

    sig { returns(T.untyped) }
    def default_filter; end

    # _@return_ — Tracers applied to every query
    # 
    # _@see_ `{Query#tracers}` — for query-specific tracers
    sig { returns(T::Array[T.untyped]) }
    def tracers; end

    # Returns the value of attribute static_validator
    sig { returns(T.untyped) }
    def static_validator; end

    # Returns the value of attribute object_from_id_proc
    sig { returns(T.untyped) }
    def object_from_id_proc; end

    # Returns the value of attribute id_from_object_proc
    sig { returns(T.untyped) }
    def id_from_object_proc; end

    # Returns the value of attribute resolve_type_proc
    sig { returns(T.untyped) }
    def resolve_type_proc; end

    sig { returns(Schema) }
    def initialize; end

    # _@return_ — True if using the new {GraphQL::Execution::Interpreter}
    sig { returns(T::Boolean) }
    def interpreter?; end

    sig { params(value: T.untyped).returns(T.untyped) }
    def interpreter=(value); end

    sig { returns(T.untyped) }
    def inspect; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
    def rescue_from(*args, &block); end

    sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
    def remove_handler(*args, &block); end

    sig { returns(T::Boolean) }
    def using_ast_analysis?; end

    # Validate a query string according to this schema.
    # 
    # _@param_ `string_or_document` — 
    sig { params(string_or_document: T.any(String, GraphQL::Language::Nodes::Document), rules: T.untyped, context: T.untyped).returns(T::Array[GraphQL::StaticValidation::Error]) }
    def validate(string_or_document, rules: nil, context: nil); end

    sig { params(kwargs: T.untyped, block: T.untyped).returns(T.untyped) }
    def define(**kwargs, &block); end

    # Attach `instrumenter` to this schema for instrumenting events of `instrumentation_type`.
    # 
    # _@param_ `instrumentation_type` — 
    # 
    # _@param_ `instrumenter`
    sig { params(instrumentation_type: Symbol, instrumenter: T.untyped).void }
    def instrument(instrumentation_type, instrumenter); end

    # _@return_ — The root types of this schema
    sig { returns(T::Array[GraphQL::BaseType]) }
    def root_types; end

    # _@return_ — `{ name => type }` pairs of types in this schema
    # 
    # _@see_ `[GraphQL::Schema::Warden]` — Restricted access to members of a schema
    sig { returns(T.untyped) }
    def types; end

    sig { returns(T.untyped) }
    def introspection_system; end

    # Returns a list of Arguments and Fields referencing a certain type
    # 
    # _@param_ `type_name` — 
    sig { params(type_name: String).returns(T::Hash[T.untyped, T.untyped]) }
    def references_to(type_name); end

    # Returns a list of Union types in which a type is a member
    # 
    # _@param_ `type` — 
    # 
    # _@return_ — list of union types of which the type is a member
    sig { params(type: GraphQL::ObjectType).returns(T::Array[GraphQL::UnionType]) }
    def union_memberships(type); end

    # Execute a query on itself. Raises an error if the schema definition is invalid.
    # 
    # _@return_ — query result, ready to be serialized as JSON
    # 
    # _@see_ `{Query#initialize}` — for arguments.
    sig { params(query_str: T.untyped, kwargs: T.untyped).returns(T::Hash[T.untyped, T.untyped]) }
    def execute(query_str = nil, **kwargs); end

    # Execute several queries on itself. Raises an error if the schema definition is invalid.
    # 
    # _@param_ `queries` — Keyword arguments for each query
    # 
    # _@param_ `context` — Multiplex-level context
    # 
    # _@return_ — One result for each query in the input
    # 
    # Run several queries at once
    # ```ruby
    # context = { ... }
    # queries = [
    #   { query: params[:query_1], variables: params[:variables_1], context: context },
    #   { query: params[:query_2], variables: params[:variables_2], context: context },
    # ]
    # results = MySchema.multiplex(queries)
    # render json: {
    #   result_1: results[0],
    #   result_2: results[1],
    # }
    # ```
    # 
    # _@see_ `{Query#initialize}` — for query keyword arguments
    # 
    # _@see_ `{Execution::Multiplex#run_queries}` — for multiplex keyword arguments
    sig { params(queries: T::Array[T::Hash[T.untyped, T.untyped]], kwargs: T.untyped).returns(T::Array[T::Hash[T.untyped, T.untyped]]) }
    def multiplex(queries, **kwargs); end

    # Search for a schema member using a string path
    # Schema.find("Ensemble.musicians")
    # 
    # _@param_ `path` — A dot-separated path to the member
    # 
    # _@return_ — A GraphQL Schema Member
    # 
    # Finding a Field
    # ```ruby
    # ```
    # 
    # _@see_ `{GraphQL::Schema::Finder}` — for more examples
    sig { params(path: String).returns(T.any(GraphQL::BaseType, GraphQL::Field, GraphQL::Argument, GraphQL::Directive)) }
    def find(path); end

    # Resolve field named `field_name` for type `parent_type`.
    # Handles dynamic fields `__typename`, `__type` and `__schema`, too
    # 
    # _@param_ `parent_type` — 
    # 
    # _@param_ `field_name` — 
    # 
    # _@return_ — The field named `field_name` on `parent_type`
    # 
    # _@see_ `[GraphQL::Schema::Warden]` — Restricted access to members of a schema
    sig { params(parent_type: T.any(String, GraphQL::BaseType), field_name: String).returns(T.nilable(GraphQL::Field)) }
    def get_field(parent_type, field_name); end

    # Fields for this type, after instrumentation is applied
    sig { params(type: T.untyped).returns(T::Hash[String, GraphQL::Field]) }
    def get_fields(type); end

    sig { params(ast_node: T.untyped, context: T.untyped).returns(T.untyped) }
    def type_from_ast(ast_node, context:); end

    # _@param_ `type_defn` — the type whose members you want to retrieve
    # 
    # _@return_ — types which belong to `type_defn` in this schema
    # 
    # _@see_ `[GraphQL::Schema::Warden]` — Restricted access to members of a schema
    sig { params(type_defn: T.any(GraphQL::InterfaceType, GraphQL::UnionType)).returns(T::Array[GraphQL::ObjectType]) }
    def possible_types(type_defn); end

    # 
    # _@see_ `[GraphQL::Schema::Warden]` — Resticted access to root types
    sig { params(operation: T.untyped).returns(T.nilable(GraphQL::ObjectType)) }
    def root_type_for_operation(operation); end

    sig { params(operation: T.untyped).returns(T.untyped) }
    def execution_strategy_for_operation(operation); end

    # Determine the GraphQL type for a given object.
    # This is required for unions and interfaces (including Relay's `Node` interface)
    # 
    # _@param_ `type` — the abstract type which is being resolved
    # 
    # _@param_ `object` — An application object which GraphQL is currently resolving on
    # 
    # _@param_ `ctx` — The context for the current query
    # 
    # _@return_ — The type for exposing `object` in GraphQL
    # 
    # _@see_ `[GraphQL::Schema::Warden]` — Restricted access to members of a schema
    sig { params(type: T.any(GraphQL::UnionType, T.untyped), object: T.untyped, ctx: GraphQL::Query::Context).returns(GraphQL::ObjectType) }
    def resolve_type(type, object, ctx = :__undefined__); end

    # This is a compatibility hack so that instance-level and class-level
    # methods can get correctness checks without calling one another
    sig { params(type: T.untyped, object: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def check_resolved_type(type, object, ctx = :__undefined__); end

    sig { params(new_resolve_type_proc: GraphQL::ObjectType).returns(T.untyped) }
    def resolve_type=(new_resolve_type_proc); end

    # Fetch an application object by its unique id
    # 
    # _@param_ `id` — A unique identifier, provided previously by this GraphQL schema
    # 
    # _@param_ `ctx` — The context for the current query
    # 
    # _@return_ — The application object identified by `id`
    sig { params(id: String, ctx: GraphQL::Query::Context).returns(T.untyped) }
    def object_from_id(id, ctx); end

    # _@param_ `new_proc` — A new callable for fetching objects by ID
    sig { params(new_proc: T.untyped).returns(T.untyped) }
    def object_from_id=(new_proc); end

    # When we encounter a type error during query execution, we call this hook.
    # 
    # You can use this hook to write a log entry,
    # add a {GraphQL::ExecutionError} to the response (with `ctx.add_error`)
    # or raise an exception and halt query execution.
    # 
    # _@param_ `err` — The error encountered during execution
    # 
    # _@param_ `ctx` — The context for the field where the error occurred
    # 
    # _@return_ — void
    # 
    # A `nil` is encountered by a non-null field
    # ```ruby
    # type_error ->(err, query_ctx) {
    #   err.is_a?(GraphQL::InvalidNullError) # => true
    # }
    # ```
    # 
    # An object doesn't resolve to one of a {UnionType}'s members
    # ```ruby
    # type_error ->(err, query_ctx) {
    #   err.is_a?(GraphQL::UnresolvedTypeError) # => true
    # }
    # ```
    # 
    # _@see_ `{DefaultTypeError}` — is the default behavior.
    sig { params(err: T.untyped, ctx: GraphQL::Query::Context).returns(T.untyped) }
    def type_error(err, ctx); end

    # _@param_ `new_proc` — A new callable for handling type errors during execution
    sig { params(new_proc: T.untyped).returns(T.untyped) }
    def type_error=(new_proc); end

    # A function to call when {#execute} receives an invalid query string
    # 
    # _@param_ `err` — The error encountered during parsing
    # 
    # _@param_ `ctx` — The context for the query where the error occurred
    # 
    # _@return_ — void
    # 
    # _@see_ `{DefaultParseError}` — is the default behavior.
    sig { params(err: GraphQL::ParseError, ctx: GraphQL::Query::Context).returns(T.untyped) }
    def parse_error(err, ctx); end

    # _@param_ `new_proc` — A new callable for handling parse errors during execution
    sig { params(new_proc: T.untyped).returns(T.untyped) }
    def parse_error=(new_proc); end

    # Get a unique identifier from this object
    # 
    # _@param_ `object` — An application object
    # 
    # _@param_ `type` — The current type definition
    # 
    # _@param_ `ctx` — the context for the current query
    # 
    # _@return_ — a unique identifier for `object` which clients can use to refetch it
    sig { params(object: T.untyped, type: GraphQL::BaseType, ctx: GraphQL::Query::Context).returns(String) }
    def id_from_object(object, type, ctx); end

    # _@param_ `new_proc` — A new callable for generating unique IDs
    sig { params(new_proc: T.untyped).returns(T.untyped) }
    def id_from_object=(new_proc); end

    # Create schema with the result of an introspection query.
    # 
    # _@param_ `introspection_result` — A response from {GraphQL::Introspection::INTROSPECTION_QUERY}
    # 
    # _@return_ — the schema described by `input`
    sig { params(introspection_result: T::Hash[T.untyped, T.untyped]).returns(GraphQL::Schema) }
    def self.from_introspection(introspection_result); end

    # Create schema from an IDL schema or file containing an IDL definition.
    # 
    # _@param_ `definition_or_path` — A schema definition string, or a path to a file containing the definition
    # 
    # _@param_ `default_resolve` — A callable for handling field resolution
    # 
    # _@param_ `parser` — An object for handling definition string parsing (must respond to `parse`)
    # 
    # _@return_ — the schema described by `document`
    sig { params(definition_or_path: String, default_resolve: T::Array[T.untyped], parser: T.untyped).returns(GraphQL::Schema) }
    def self.from_definition(definition_or_path, default_resolve: BuildFromDefinition::DefaultResolve, parser: BuildFromDefinition::DefaultParser); end

    # _@return_ — The method name to lazily resolve `obj`, or nil if `obj`'s class wasn't registered wtih {#lazy_resolve}.
    sig { params(obj: T.untyped).returns(T.nilable(Symbol)) }
    def lazy_method_name(obj); end

    # _@return_ — True if this object should be lazily resolved
    sig { params(obj: T.untyped).returns(T::Boolean) }
    def lazy?(obj); end

    # Return the GraphQL IDL for the schema
    # 
    # _@param_ `context` — 
    # 
    # _@param_ `only` — 
    # 
    # _@param_ `except` — 
    sig { params(only: T.nilable(T::Array[T.untyped]), except: T.nilable(T::Array[T.untyped]), context: T::Hash[T.untyped, T.untyped]).returns(String) }
    def to_definition(only: nil, except: nil, context: {}); end

    # Return the GraphQL::Language::Document IDL AST for the schema
    sig { returns(T.untyped) }
    def to_document; end

    # Return the Hash response of {Introspection::INTROSPECTION_QUERY}.
    # 
    # _@param_ `context` — 
    # 
    # _@param_ `only` — 
    # 
    # _@param_ `except` — 
    # 
    # _@return_ — GraphQL result
    sig { params(only: T.nilable(T::Array[T.untyped]), except: T.nilable(T::Array[T.untyped]), context: T::Hash[T.untyped, T.untyped]).returns(T::Hash[T.untyped, T.untyped]) }
    def as_json(only: nil, except: nil, context: {}); end

    # Returns the JSON response of {Introspection::INTROSPECTION_QUERY}.
    # 
    # _@see_ `{#as_json}`
    sig { params(args: T.untyped).returns(String) }
    def to_json(*args); end

    sig { returns(T::Boolean) }
    def new_connections?; end

    # Returns the value of attribute connections
    sig { returns(T.untyped) }
    def connections; end

    # Sets the attribute connections
    # 
    # _@param_ `value` — the value to set the attribute connections to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def connections=(value); end

    sig { returns(T.untyped) }
    def self.graphql_definition; end

    sig { params(plugin: T.untyped, options: T.untyped).returns(T.untyped) }
    def self.use(plugin, options = {}); end

    sig { returns(T.untyped) }
    def self.plugins; end

    sig { returns(T.untyped) }
    def self.to_graphql; end

    # _@return_ — if installed
    sig { returns(GraphQL::Pagination::Connections) }
    def self.connections; end

    # _@return_ — if installed
    sig { params(value: GraphQL::Pagination::Connections).returns(GraphQL::Pagination::Connections) }
    def self.connections=(value); end

    sig { params(new_query_object: T.untyped).returns(T.untyped) }
    def self.query(new_query_object = nil); end

    sig { params(new_mutation_object: T.untyped).returns(T.untyped) }
    def self.mutation(new_mutation_object = nil); end

    sig { params(new_subscription_object: T.untyped).returns(T.untyped) }
    def self.subscription(new_subscription_object = nil); end

    sig { params(new_introspection_namespace: T.untyped).returns(T.untyped) }
    def self.introspection(new_introspection_namespace = nil); end

    sig { params(new_encoder: T.untyped).returns(T.untyped) }
    def self.cursor_encoder(new_encoder = nil); end

    sig { params(new_default_max_page_size: T.untyped).returns(T.untyped) }
    def self.default_max_page_size(new_default_max_page_size = nil); end

    sig { params(new_query_execution_strategy: T.untyped).returns(T.untyped) }
    def self.query_execution_strategy(new_query_execution_strategy = nil); end

    sig { params(new_mutation_execution_strategy: T.untyped).returns(T.untyped) }
    def self.mutation_execution_strategy(new_mutation_execution_strategy = nil); end

    sig { params(new_subscription_execution_strategy: T.untyped).returns(T.untyped) }
    def self.subscription_execution_strategy(new_subscription_execution_strategy = nil); end

    sig { params(max_complexity: T.untyped).returns(T.untyped) }
    def self.max_complexity(max_complexity = nil); end

    sig { params(new_error_bubbling: T.untyped).returns(T.untyped) }
    def self.error_bubbling(new_error_bubbling = nil); end

    sig { params(new_max_depth: T.untyped).returns(T.untyped) }
    def self.max_depth(new_max_depth = nil); end

    sig { returns(T.untyped) }
    def self.disable_introspection_entry_points; end

    sig { returns(T::Boolean) }
    def self.disable_introspection_entry_points?; end

    sig { params(new_orphan_types: T.untyped).returns(T.untyped) }
    def self.orphan_types(*new_orphan_types); end

    sig { returns(T.untyped) }
    def self.default_execution_strategy; end

    sig { params(new_context_class: T.untyped).returns(T.untyped) }
    def self.context_class(new_context_class = nil); end

    sig { params(err_classes: T.untyped, handler_block: T.untyped).returns(T.untyped) }
    def self.rescue_from(*err_classes, &handler_block); end

    sig { returns(T.untyped) }
    def self.rescues; end

    sig { params(type: T.untyped, obj: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def self.resolve_type(type, obj, ctx); end

    sig { params(node_id: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def self.object_from_id(node_id, ctx); end

    sig { params(object: T.untyped, type: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def self.id_from_object(object, type, ctx); end

    sig { params(member: T.untyped, context: T.untyped).returns(T::Boolean) }
    def self.visible?(member, context); end

    sig { params(member: T.untyped, context: T.untyped).returns(T::Boolean) }
    def self.accessible?(member, context); end

    # This hook is called when a client tries to access one or more
    # fields that fail the `accessible?` check.
    # 
    # By default, an error is added to the response. Override this hook to
    # track metrics or return a different error to the client.
    # 
    # _@param_ `error` — The analysis error for this check
    # 
    # _@return_ — Return an error to skip the query
    sig { params(error: GraphQL::Authorization::InaccessibleFieldsError).returns(T.nilable(AnalysisError)) }
    def self.inaccessible_fields(error); end

    # This hook is called when an object fails an `authorized?` check.
    # You might report to your bug tracker here, so you can correct
    # the field resolvers not to return unauthorized objects.
    # 
    # By default, this hook just replaces the unauthorized object with `nil`.
    # 
    # Whatever value is returned from this method will be used instead of the
    # unauthorized object (accessible as `unauthorized_error.object`). If an
    # error is raised, then `nil` will be used.
    # 
    # If you want to add an error to the `"errors"` key, raise a {GraphQL::ExecutionError}
    # in this hook.
    # 
    # _@param_ `unauthorized_error` — 
    # 
    # _@return_ — The returned object will be put in the GraphQL response
    sig { params(unauthorized_error: GraphQL::UnauthorizedError).returns(T.untyped) }
    def self.unauthorized_object(unauthorized_error); end

    # This hook is called when a field fails an `authorized?` check.
    # 
    # By default, this hook implements the same behavior as unauthorized_object.
    # 
    # Whatever value is returned from this method will be used instead of the
    # unauthorized field . If an error is raised, then `nil` will be used.
    # 
    # If you want to add an error to the `"errors"` key, raise a {GraphQL::ExecutionError}
    # in this hook.
    # 
    # _@param_ `unauthorized_error` — 
    # 
    # _@return_ — The returned field will be put in the GraphQL response
    sig { params(unauthorized_error: GraphQL::UnauthorizedFieldError).returns(T.untyped) }
    def self.unauthorized_field(unauthorized_error); end

    sig { params(type_err: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def self.type_error(type_err, ctx); end

    sig { params(lazy_class: T.untyped, value_method: T.untyped).returns(T.untyped) }
    def self.lazy_resolve(lazy_class, value_method); end

    sig { params(instrument_step: T.untyped, instrumenter: T.untyped, options: T.untyped).returns(T.untyped) }
    def self.instrument(instrument_step, instrumenter, options = {}); end

    sig { params(new_directives: T.untyped).returns(T.untyped) }
    def self.directives(new_directives = nil); end

    sig { params(new_directive: T.untyped).returns(T.untyped) }
    def self.directive(new_directive); end

    sig { returns(T.untyped) }
    def self.default_directives; end

    sig { params(new_tracer: T.untyped).returns(T.untyped) }
    def self.tracer(new_tracer); end

    sig { returns(T.untyped) }
    def self.tracers; end

    sig { params(new_analyzer: T.untyped).returns(T.untyped) }
    def self.query_analyzer(new_analyzer); end

    sig { returns(T.untyped) }
    def self.query_analyzers; end

    sig { params(new_middleware: T.untyped).returns(T.untyped) }
    def self.middleware(new_middleware = nil); end

    sig { params(new_analyzer: T.untyped).returns(T.untyped) }
    def self.multiplex_analyzer(new_analyzer); end

    sig { returns(T.untyped) }
    def self.multiplex_analyzers; end

    sig { returns(T.untyped) }
    def self.lazy_classes; end

    sig { returns(T.untyped) }
    def self.own_plugins; end

    sig { returns(T.untyped) }
    def self.own_rescues; end

    sig { returns(T.untyped) }
    def self.own_orphan_types; end

    sig { returns(T.untyped) }
    def self.own_directives; end

    sig { returns(T.untyped) }
    def self.all_instrumenters; end

    sig { returns(T.untyped) }
    def self.own_instrumenters; end

    sig { returns(T.untyped) }
    def self.own_tracers; end

    sig { returns(T.untyped) }
    def self.own_query_analyzers; end

    sig { returns(T.untyped) }
    def self.all_middleware; end

    sig { returns(T.untyped) }
    def self.own_middleware; end

    sig { returns(T.untyped) }
    def self.own_multiplex_analyzers; end

    # Given this schema member, find the class-based definition object
    # whose `method_name` should be treated as an application hook
    # 
    # _@see_ `{.visible?}`
    # 
    # _@see_ `{.accessible?}`
    # 
    # _@see_ `{.authorized?}`
    sig do
      params(
        member: T.untyped,
        method_name: T.untyped,
        args: T.untyped,
        default: T.untyped
      ).returns(T.untyped)
    end
    def self.call_on_type_class(member, method_name, *args, default:); end

    sig { params(child_class: T.untyped).returns(T.untyped) }
    def self.inherited(child_class); end

    # Call the given block at the right time, either:
    # - Right away, if `value` is not registered with `lazy_resolve`
    # - After resolving `value`, if it's registered with `lazy_resolve` (eg, `Promise`)
    sig { params(value: T.untyped).returns(T.untyped) }
    def after_lazy(value); end

    # Override this method to handle lazy objects in a custom way.
    # 
    # _@param_ `value` — an instance of a class registered with {.lazy_resolve}
    # 
    # _@param_ `ctx` — the context for this query
    # 
    # _@return_ — A GraphQL-ready (non-lazy) object
    sig { params(value: T.untyped).returns(T.untyped) }
    def self.sync_lazy(value); end

    # 
    # _@see_ `Schema.sync_lazy` — for a hook to override
    sig { params(value: T.untyped).returns(T.untyped) }
    def sync_lazy(value); end

    sig { returns(T::Boolean) }
    def rescues?; end

    # Lazily create a middleware and add it to the schema
    # (Don't add it if it's not used)
    sig { returns(T.untyped) }
    def rescue_middleware; end

    sig { returns(T.untyped) }
    def rebuild_artifacts; end

    sig { returns(T.untyped) }
    def with_definition_error_check; end

    sig { params(method_name: T.untyped, default_value: T.untyped).returns(T.untyped) }
    def self.find_inherited_value(method_name, default_value = nil); end

    # If this schema was parsed from a `.graphql` file (or other SDL),
    # this is the AST node that defined this part of the schema.
    sig { params(new_ast_node: T.untyped).returns(T.untyped) }
    def self.ast_node(new_ast_node = nil); end

    # `metadata` can store arbitrary key-values with an object.
    # 
    # _@return_ — Hash for user-defined storage
    sig { returns(T::Hash[Object, Object]) }
    def metadata; end

    # Shallow-copy this object, then apply new definitions to the copy.
    # 
    # _@return_ — A new instance, with any extended definitions
    # 
    # _@see_ `{#define}` — for arguments
    sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::Define::InstanceDefinable) }
    def redefine(**kwargs, &block); end

    # Run the definition block if it hasn't been run yet.
    # This can only be run once: the block is deleted after it's used.
    # You have to call this before using any value which could
    # come from the definition block.
    sig { void }
    def ensure_defined; end

    # Take the pending methods and put them back on this object's singleton class.
    # This reverts the process done by {#stash_dependent_methods}
    sig { void }
    def revive_dependent_methods; end

    # Find the method names which were declared as definition-dependent,
    # then grab the method definitions off of this object's class
    # and store them for later.
    # 
    # Then make a dummy method for each of those method names which:
    # 
    # - Triggers the pending definition, if there is one
    # - Calls the same method again.
    # 
    # It's assumed that {#ensure_defined} will put the original method definitions
    # back in place with {#revive_dependent_methods}.
    sig { void }
    def stash_dependent_methods; end

    # Error that is raised when [#Schema#from_definition] is passed an invalid schema definition string.
    class InvalidDocumentError < GraphQL::Error
    end

    module MethodWrappers
      # Wrap the user-provided resolve-type in a correctness check
      sig { params(type: T.untyped, obj: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def resolve_type(type, obj, ctx = :__undefined__); end
    end

    class CyclicalDefinitionError < GraphQL::Error
    end

    class Enum < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend Forwardable
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # Define a value for this enum
      # 
      # _@param_ `graphql_name` — the GraphQL value for this, usually `SCREAMING_CASE`
      # 
      # _@param_ `description` — , the GraphQL description for this value, present in documentation
      # 
      # _@param_ `value` — , the translated Ruby value for this object (defaults to `graphql_name`)
      # 
      # _@param_ `deprecation_reason` — if this object is deprecated, include a message here
      # 
      # _@see_ `{Schema::EnumValue}` — which handles these inputs by default
      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).void }
      def self.value(*args, **kwargs, &block); end

      # _@return_ — Possible values of this enum, keyed by name
      sig { returns(T::Hash[String, T.untyped]) }
      def self.values; end

      sig { returns(GraphQL::EnumType) }
      def self.to_graphql; end

      # _@return_ — for handling `value(...)` inputs and building `GraphQL::Enum::EnumValue`s out of them
      sig { params(new_enum_value_class: T.untyped).returns(Class) }
      def self.enum_value_class(new_enum_value_class = nil); end

      sig { returns(T.untyped) }
      def self.kind; end

      sig { returns(T.untyped) }
      def self.own_values; end
    end

    # Represents a list type in the schema.
    # Wraps a {Schema::Member} as a list type.
    # @see {Schema::Member::TypeSystemHelpers#to_list_type}
    class List < GraphQL::Schema::Wrapper
      sig { returns(T.untyped) }
      def to_graphql; end

      sig { returns(T.untyped) }
      def kind; end

      sig { returns(T::Boolean) }
      def list?; end

      sig { returns(T.untyped) }
      def to_type_signature; end
    end

    class Field
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::AcceptsDefinition
      include GraphQL::Schema::Member::HasArguments
      include GraphQL::Schema::Member::HasAstNode
      include GraphQL::Schema::Member::HasPath
      NO_ARGS = T.let({}.freeze, T.untyped)

      # _@return_ — the GraphQL name for this field, camelized unless `camelize: false` is provided
      sig { returns(String) }
      def name; end

      # Sets the attribute description
      # 
      # _@param_ `value` — the value to set the attribute description to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def description=(value); end

      # _@return_ — If present, the field is marked as deprecated with this documentation
      sig { returns(T.nilable(String)) }
      def deprecation_reason; end

      # _@return_ — If present, the field is marked as deprecated with this documentation
      sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
      def deprecation_reason=(value); end

      # _@return_ — Method or hash key on the underlying object to look up
      sig { returns(Symbol) }
      def method_sym; end

      # _@return_ — Method or hash key on the underlying object to look up
      sig { returns(String) }
      def method_str; end

      # _@return_ — The method on the type to look up
      sig { returns(Symbol) }
      def resolver_method; end

      # _@return_ — The type that this field belongs to
      sig { returns(Class) }
      def owner; end

      # _@return_ — the original name of the field, passed in by the user
      sig { returns(Symbol) }
      def original_name; end

      # _@return_ — The {Schema::Resolver} this field was derived from, if there is one
      sig { returns(T.nilable(Class)) }
      def resolver; end

      # _@return_ — Apply tracing to this field? (Default: skip scalars, this is the override value)
      sig { returns(T::Boolean) }
      def trace; end

      sig { returns(T.nilable(String)) }
      def subscription_scope; end

      # Create a field instance from a list of arguments, keyword arguments, and a block.
      # 
      # This method implements prioritization between the `resolver` or `mutation` defaults
      # and the local overrides via other keywords.
      # 
      # It also normalizes positional arguments into keywords for {Schema::Field#initialize}.
      # 
      # _@param_ `resolver` — A {GraphQL::Schema::Resolver} class to use for field configuration
      # 
      # _@param_ `mutation` — A {GraphQL::Schema::Mutation} class to use for field configuration
      # 
      # _@param_ `subscription` — A {GraphQL::Schema::Subscription} class to use for field configuration
      # 
      # _@return_ — an instance of `self
      # 
      # _@see_ `{.initialize}` — for other options
      sig do
        params(
          type: T.untyped,
          name: T.untyped,
          desc: T.untyped,
          mutation: T.nilable(Class),
          resolver: T.nilable(Class),
          subscription: T.nilable(Class),
          kwargs: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def self.from_options(type = nil, name = nil, desc = nil, mutation: nil, resolver: nil, subscription: nil, **kwargs, &block); end

      # Can be set with `connection: true|false` or inferred from a type name ending in `*Connection`
      # 
      # _@return_ — if true, this field will be wrapped with Relay connection behavior
      sig { returns(T::Boolean) }
      def connection?; end

      # _@return_ — if true, the return type's `.scope_items` method will be applied to this field's return value
      sig { returns(T::Boolean) }
      def scoped?; end

      # _@return_ — Should we warn if this field's name conflicts with a built-in method?
      sig { returns(T::Boolean) }
      def method_conflict_warning?; end

      # _@param_ `name` — The underscore-cased version of this field name (will be camelized for the GraphQL API)
      # 
      # _@param_ `type` — The return type of this field
      # 
      # _@param_ `owner` — The type that this field belongs to
      # 
      # _@param_ `null` — `true` if this field may return `null`, `false` if it is never `null`
      # 
      # _@param_ `description` — Field description
      # 
      # _@param_ `deprecation_reason` — If present, the field is marked "deprecated" with this message
      # 
      # _@param_ `method` — The method to call on the underlying object to resolve this field (defaults to `name`)
      # 
      # _@param_ `hash_key` — The hash key to lookup on the underlying object (if its a Hash) to resolve this field (defaults to `name` or `name.to_s`)
      # 
      # _@param_ `resolver_method` — The method on the type to call to resolve this field (defaults to `name`)
      # 
      # _@param_ `connection` — `true` if this field should get automagic connection behavior; default is to infer by `*Connection` in the return type name
      # 
      # _@param_ `max_page_size` — For connections, the maximum number of items to return from this field
      # 
      # _@param_ `introspection` — If true, this field will be marked as `#introspection?` and the name may begin with `__`
      # 
      # _@param_ `resolve` — **deprecated** for compatibility with <1.8.0
      # 
      # _@param_ `field` — **deprecated** for compatibility with <1.8.0
      # 
      # _@param_ `function` — **deprecated** for compatibility with <1.8.0
      # 
      # _@param_ `resolver_class` — (Private) A {Schema::Resolver} which this field was derived from. Use `resolver:` to create a field with a resolver.
      # 
      # _@param_ `arguments` — Arguments for this field (may be added in the block, also)
      # 
      # _@param_ `camelize` — If true, the field name will be camelized when building the schema
      # 
      # _@param_ `complexity` — When provided, set the complexity for this field
      # 
      # _@param_ `scope` — If true, the return type's `.scope_items` method will be called on the return value
      # 
      # _@param_ `subscription_scope` — A key in `context` which will be used to scope subscription payloads
      # 
      # _@param_ `extensions` — Named extensions to apply to this field (see also {#extension})
      # 
      # _@param_ `trace` — If true, a {GraphQL::Tracing} tracer will measure this scalar field
      # 
      # _@param_ `ast_node` — If this schema was parsed from definition, this AST node defined the field
      # 
      # _@param_ `method_conflict_warning` — If false, skip the warning if this field's method conflicts with a built-in method
      sig do
        params(
          type: T.nilable(T.any(Class, GraphQL::BaseType, T::Array[T.untyped])),
          name: T.nilable(Symbol),
          owner: T.nilable(Class),
          null: T.nilable(T::Boolean),
          field: T.nilable(T.any(GraphQL::Field, GraphQL::Schema::Field)),
          function: T.nilable(GraphQL::Function),
          description: T.nilable(String),
          deprecation_reason: T.nilable(String),
          method: T.nilable(Symbol),
          hash_key: T.nilable(T.any(String, Symbol)),
          resolver_method: T.nilable(Symbol),
          resolve: T.nilable(T::Array[T.untyped]),
          connection: T.nilable(T::Boolean),
          max_page_size: T.nilable(Integer),
          scope: T.nilable(T::Boolean),
          introspection: T::Boolean,
          camelize: T::Boolean,
          trace: T.nilable(T::Boolean),
          complexity: Numeric,
          ast_node: T.nilable(Language::Nodes::FieldDefinition),
          extras: T.untyped,
          extensions: T::Array[T.any(Class, T::Hash[Class, T.untyped])],
          resolver_class: T.nilable(Class),
          subscription_scope: T.nilable(T.any(Symbol, String)),
          relay_node_field: T.untyped,
          relay_nodes_field: T.untyped,
          method_conflict_warning: T::Boolean,
          arguments: T.untyped,
          definition_block: T.untyped
        ).returns(Field)
      end
      def initialize(type: nil, name: nil, owner: nil, null: nil, field: nil, function: nil, description: nil, deprecation_reason: nil, method: nil, hash_key: nil, resolver_method: nil, resolve: nil, connection: nil, max_page_size: nil, scope: nil, introspection: false, camelize: true, trace: nil, complexity: 1, ast_node: nil, extras: [], extensions: [], resolver_class: nil, subscription_scope: nil, relay_node_field: false, relay_nodes_field: false, method_conflict_warning: true, arguments: {}, &definition_block); end

      # _@param_ `text` — 
      sig { params(text: T.nilable(String)).returns(String) }
      def description(text = nil); end

      # Read extension instances from this field,
      # or add new classes/options to be initialized on this field.
      # Extensions are executed in the order they are added.
      # 
      # _@param_ `extensions` — Add extensions to this field. For hash elements, only the first key/value is used.
      # 
      # _@return_ — extensions to apply to this field
      # 
      # adding an extension
      # ```ruby
      # extensions([MyExtensionClass])
      # ```
      # 
      # adding multiple extensions
      # ```ruby
      # extensions([MyExtensionClass, AnotherExtensionClass])
      # ```
      # 
      # adding an extension with options
      # ```ruby
      # extensions([MyExtensionClass, { AnotherExtensionClass => { filter: true } }])
      # ```
      sig { params(new_extensions: T.nilable(T::Array[T.any(Class, T::Hash[Class, T.untyped])])).returns(T::Array[GraphQL::Schema::FieldExtension]) }
      def extensions(new_extensions = nil); end

      # Add `extension` to this field, initialized with `options` if provided.
      # 
      # _@param_ `extension` — subclass of {Schema::Fieldextension}
      # 
      # _@param_ `options` — if provided, given as `options:` when initializing `extension`.
      # 
      # adding an extension
      # ```ruby
      # extension(MyExtensionClass)
      # ```
      # 
      # adding an extension with options
      # ```ruby
      # extension(MyExtensionClass, filter: true)
      # ```
      sig { params(extension: Class, options: T.untyped).returns(T.untyped) }
      def extension(extension, options = nil); end

      # Read extras (as symbols) from this field,
      # or add new extras to be opted into by this field's resolver.
      # 
      # _@param_ `new_extras` — Add extras to this field
      sig { params(new_extras: T.nilable(T::Array[Symbol])).returns(T::Array[Symbol]) }
      def extras(new_extras = nil); end

      sig { params(new_complexity: T.untyped).returns(T.untyped) }
      def complexity(new_complexity); end

      # _@return_ — Applied to connections if present
      sig { returns(T.nilable(Integer)) }
      def max_page_size; end

      sig { returns(GraphQL::Field) }
      def to_graphql; end

      sig { returns(T.untyped) }
      def type; end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def visible?(context); end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def accessible?(context); end

      sig { params(object: T.untyped, args: T.untyped, context: T.untyped).returns(T::Boolean) }
      def authorized?(object, args, context); end

      # Implement {GraphQL::Field}'s resolve API.
      # 
      # Eventually, we might hook up field instances to execution in another way. TBD.
      # 
      # _@see_ `#resolve` — for how the interpreter hooks up to it
      sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def resolve_field(obj, args, ctx); end

      # This method is called by the interpreter for each field.
      # You can extend it in your base field classes.
      # 
      # _@param_ `object` — An instance of some type class, wrapping an application object
      # 
      # _@param_ `args` — A symbol-keyed hash of Ruby keyword arguments. (Empty if no args)
      # 
      # _@param_ `ctx` — 
      sig { params(object: GraphQL::Schema::Object, args: T::Hash[T.untyped, T.untyped], ctx: GraphQL::Query::Context).returns(T.untyped) }
      def resolve(object, args, ctx); end

      # Find a way to resolve this field, checking:
      # 
      # - Hash keys, if the wrapped object is a hash;
      # - A method on the wrapped object;
      # - Or, raise not implemented.
      # 
      # This can be overridden by defining a method on the object type.
      # 
      # _@param_ `obj` — 
      # 
      # _@param_ `ruby_kwargs` — 
      # 
      # _@param_ `ctx` — 
      sig { params(obj: GraphQL::Schema::Object, ruby_kwargs: T::Hash[Symbol, T.untyped], ctx: GraphQL::Query::Context).returns(T.untyped) }
      def resolve_field_method(obj, ruby_kwargs, ctx); end

      # _@param_ `ctx` — 
      sig { params(extra_name: T.untyped, ctx: GraphQL::Query::Context::FieldResolutionContext).returns(T.untyped) }
      def fetch_extra(extra_name, ctx); end

      # Convert a GraphQL arguments instance into a Ruby-style hash.
      # 
      # _@param_ `obj` — The object where this field is being resolved
      # 
      # _@param_ `graphql_args` — 
      # 
      # _@param_ `field_ctx` — 
      sig { params(obj: GraphQL::Schema::Object, graphql_args: GraphQL::Query::Arguments, field_ctx: GraphQL::Query::Context::FieldResolutionContext).returns(T::Hash[Symbol, T.untyped]) }
      def to_ruby_args(obj, graphql_args, field_ctx); end

      sig { params(obj: T.untyped, ruby_kwargs: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
      def public_send_field(obj, ruby_kwargs, field_ctx); end

      # Wrap execution with hooks.
      # Written iteratively to avoid big stack traces.
      # 
      # _@return_ — Whatever the
      sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def with_extensions(obj, args, ctx); end

      sig do
        params(
          memos: T.untyped,
          obj: T.untyped,
          args: T.untyped,
          ctx: T.untyped,
          idx: T.untyped
        ).returns(T.untyped)
      end
      def run_extensions_before_resolve(memos, obj, args, ctx, idx: 0); end

      # _@return_ — A description of this member's place in the GraphQL schema
      sig { returns(String) }
      def path; end

      # If this schema was parsed from a `.graphql` file (or other SDL),
      # this is the AST node that defined this part of the schema.
      sig { params(new_ast_node: T.untyped).returns(T.untyped) }
      def ast_node(new_ast_node = nil); end

      # _@return_ — An instance of {arguments_class}, created from `*args`
      # 
      # _@see_ `{GraphQL::Schema::Argument#initialize}` — for parameters
      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(GraphQL::Schema::Argument) }
      def argument(*args, **kwargs, &block); end

      # Register this argument with the class.
      # 
      # _@param_ `arg_defn` — 
      sig { params(arg_defn: GraphQL::Schema::Argument).returns(GraphQL::Schema::Argument) }
      def add_argument(arg_defn); end

      # _@return_ — Hash<String => GraphQL::Schema::Argument] Arguments defined on this thing, keyed by name. Includes inherited definitions
      sig { returns(T.untyped) }
      def arguments; end

      # _@param_ `new_arg_class` — A class to use for building argument definitions
      sig { params(new_arg_class: T.nilable(Class)).returns(T.untyped) }
      def argument_class(new_arg_class = nil); end

      sig { returns(T.untyped) }
      def own_arguments; end

      # A cached result of {.to_graphql}.
      # It's cached here so that user-overridden {.to_graphql} implementations
      # are also cached
      sig { returns(T.untyped) }
      def graphql_definition; end

      # This is for a common interface with .define-based types
      sig { returns(T.untyped) }
      def type_class; end

      # Wipe out the cached graphql_definition so that `.to_graphql` will be called again.
      sig { params(original: T.untyped).returns(T.untyped) }
      def initialize_copy(original); end

      class ScopeExtension < GraphQL::Schema::FieldExtension
        sig { params(value: T.untyped, context: T.untyped, rest: T.untyped).returns(T.untyped) }
        def after_resolve(value:, context:, **rest); end
      end

      class ConnectionExtension < GraphQL::Schema::FieldExtension
        sig { returns(T.untyped) }
        def apply; end

        # Remove pagination args before passing it to a user method
        sig { params(object: T.untyped, arguments: T.untyped, context: T.untyped).returns(T.untyped) }
        def resolve(object:, arguments:, context:); end

        sig do
          params(
            value: T.untyped,
            object: T.untyped,
            arguments: T.untyped,
            context: T.untyped,
            memo: T.untyped
          ).returns(T.untyped)
        end
        def after_resolve(value:, object:, arguments:, context:, memo:); end
      end
    end

    class Union < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(types: T.untyped).returns(T.untyped) }
      def self.possible_types(*types); end

      sig { returns(T.untyped) }
      def self.to_graphql; end

      sig { returns(T.untyped) }
      def self.kind; end
    end

    # Find schema members using string paths
    # 
    # @example Finding object types
    #   MySchema.find("SomeObjectType")
    # 
    # @example Finding fields
    #   MySchema.find("SomeObjectType.myField")
    # 
    # @example Finding arguments
    #   MySchema.find("SomeObjectType.myField.anArgument")
    # 
    # @example Finding directives
    #   MySchema.find("@include")
    class Finder
      sig { params(schema: T.untyped).returns(Finder) }
      def initialize(schema); end

      sig { params(path: T.untyped).returns(T.untyped) }
      def find(path); end

      # Returns the value of attribute schema
      sig { returns(T.untyped) }
      def schema; end

      sig { params(directive: T.untyped, path: T.untyped).returns(T.untyped) }
      def find_in_directive(directive, path:); end

      sig { params(type: T.untyped, path: T.untyped).returns(T.untyped) }
      def find_in_type(type, path:); end

      sig { params(type: T.untyped, kind: T.untyped, path: T.untyped).returns(T.untyped) }
      def find_in_fields_type(type, kind:, path:); end

      sig { params(field: T.untyped, path: T.untyped).returns(T.untyped) }
      def find_in_field(field, path:); end

      sig { params(input_object: T.untyped, path: T.untyped).returns(T.untyped) }
      def find_in_input_object(input_object, path:); end

      sig { params(enum_type: T.untyped, path: T.untyped).returns(T.untyped) }
      def find_in_enum_type(enum_type, path:); end

      class MemberNotFoundError < ArgumentError
      end
    end

    # You can use the result of {GraphQL::Introspection::INTROSPECTION_QUERY}
    # to make a schema. This schema is missing some important details like
    # `resolve` functions, but it does include the full type system,
    # so you can use it to validate queries.
    module Loader
      extend GraphQL::Schema::Loader
      NullResolveType = T.let(->(type, obj, ctx) {
  raise(GraphQL::RequiredImplementationMissingError, "This schema was loaded from string, so it can't resolve types for objects")
}, T.untyped)
      NullScalarCoerce = T.let(->(val, _ctx) { val }, T.untyped)

      # Create schema with the result of an introspection query.
      # 
      # _@param_ `introspection_result` — A response from {GraphQL::Introspection::INTROSPECTION_QUERY}
      # 
      # _@return_ — the schema described by `input`
      # 
      # _@deprecated_ — Use {GraphQL::Schema.from_introspection} instead
      sig { params(introspection_result: T::Hash[T.untyped, T.untyped]).returns(GraphQL::Schema) }
      def load(introspection_result); end

      sig { params(types: T.untyped, type: T.untyped).returns(T.untyped) }
      def self.resolve_type(types, type); end

      sig { params(default_value_str: T.untyped, input_value_ast: T.untyped).returns(T.untyped) }
      def self.extract_default_value(default_value_str, input_value_ast); end

      sig { params(type: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
      def self.define_type(type, type_resolver); end

      # Create schema with the result of an introspection query.
      # 
      # _@param_ `introspection_result` — A response from {GraphQL::Introspection::INTROSPECTION_QUERY}
      # 
      # _@return_ — the schema described by `input`
      # 
      # _@deprecated_ — Use {GraphQL::Schema.from_introspection} instead
      sig { params(introspection_result: T::Hash[T.untyped, T.untyped]).returns(GraphQL::Schema) }
      def self.load(introspection_result); end
    end

    # The base class for things that make up the schema,
    # eg objects, enums, scalars.
    # 
    # @api private
    class Member
      include GraphQL::Schema::Member::GraphQLTypeNames
      extend GraphQL::Schema::Member::CachedGraphQLDefinition
      extend GraphQL::Relay::TypeExtensions
      extend GraphQL::Schema::Member::BaseDSLMethods
      extend GraphQL::Schema::Member::TypeSystemHelpers
      extend GraphQL::Schema::Member::Scoped
      extend GraphQL::Schema::Member::RelayShortcuts
      extend GraphQL::Schema::Member::HasPath
      extend GraphQL::Schema::Member::HasAstNode
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # If this schema was parsed from a `.graphql` file (or other SDL),
      # this is the AST node that defined this part of the schema.
      sig { params(new_ast_node: T.untyped).returns(T.untyped) }
      def self.ast_node(new_ast_node = nil); end

      # _@return_ — A description of this member's place in the GraphQL schema
      sig { returns(String) }
      def self.path; end

      sig { params(new_edge_type_class: T.untyped).returns(T.untyped) }
      def self.edge_type_class(new_edge_type_class = nil); end

      sig { params(new_connection_type_class: T.untyped).returns(T.untyped) }
      def self.connection_type_class(new_connection_type_class = nil); end

      sig { returns(T.untyped) }
      def self.edge_type; end

      sig { returns(T.untyped) }
      def self.connection_type; end

      # This is called when a field has `scope: true`.
      # The field's return type class receives this call.
      # 
      # By default, it's a no-op. Override it to scope your objects.
      # 
      # _@param_ `items` — Some list-like object (eg, Array, ActiveRecord::Relation)
      # 
      # _@param_ `context` — 
      # 
      # _@return_ — Another list-like object, scoped to the current context
      sig { params(items: T.untyped, context: GraphQL::Query::Context).returns(T.untyped) }
      def self.scope_items(items, context); end

      # _@return_ — Make a non-null-type representation of this type
      sig { returns(Schema::NonNull) }
      def self.to_non_null_type; end

      # _@return_ — Make a list-type representation of this type
      sig { returns(Schema::List) }
      def self.to_list_type; end

      # _@return_ — true if this is a non-nullable type. A nullable list of non-nullables is considered nullable.
      sig { returns(T::Boolean) }
      def self.non_null?; end

      # _@return_ — true if this is a list type. A non-nullable list is considered a list.
      sig { returns(T::Boolean) }
      def self.list?; end

      sig { returns(T.untyped) }
      def self.to_type_signature; end

      sig { returns(GraphQL::TypeKinds::TypeKind) }
      def self.kind; end

      # Call this with a new name to override the default name for this schema member; OR
      # call it without an argument to get the name of this schema member
      # 
      # The default name is implemented in default_graphql_name
      # 
      # _@param_ `new_name` — 
      sig { params(new_name: T.nilable(String)).returns(String) }
      def self.graphql_name(new_name = nil); end

      # Just a convenience method to point out that people should use graphql_name instead
      sig { params(new_name: T.untyped).returns(T.untyped) }
      def self.name(new_name = nil); end

      # Call this method to provide a new description; OR
      # call it without an argument to get the description
      # 
      # _@param_ `new_description` — 
      sig { params(new_description: T.nilable(String)).returns(String) }
      def self.description(new_description = nil); end

      # _@return_ — If true, this object is part of the introspection system
      sig { params(new_introspection: T.untyped).returns(T::Boolean) }
      def self.introspection(new_introspection = nil); end

      sig { returns(T::Boolean) }
      def self.introspection?; end

      # The mutation this type was derived from, if it was derived from a mutation
      sig { params(mutation_class: T.untyped).returns(Class) }
      def self.mutation(mutation_class = nil); end

      # _@return_ — Convert this type to a legacy-style object.
      sig { returns(GraphQL::BaseType) }
      def self.to_graphql; end

      sig { returns(T.untyped) }
      def self.overridden_graphql_name; end

      # Creates the default name for a schema member.
      # The default name is the Ruby constant name,
      # without any namespaces and with any `-Type` suffix removed
      sig { returns(T.untyped) }
      def self.default_graphql_name; end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def self.visible?(context); end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def self.accessible?(context); end

      sig { params(object: T.untyped, context: T.untyped).returns(T::Boolean) }
      def self.authorized?(object, context); end

      sig { params(method_name: T.untyped, default_value: T.untyped).returns(T.untyped) }
      def self.find_inherited_value(method_name, default_value = nil); end

      # Define a custom connection type for this object type
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
      def self.define_connection(**kwargs, &block); end

      # Define a custom edge type for this object type
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
      def self.define_edge(**kwargs, &block); end

      # A cached result of {.to_graphql}.
      # It's cached here so that user-overridden {.to_graphql} implementations
      # are also cached
      sig { returns(T.untyped) }
      def self.graphql_definition; end

      # This is for a common interface with .define-based types
      sig { returns(T.untyped) }
      def self.type_class; end

      # Wipe out the cached graphql_definition so that `.to_graphql` will be called again.
      sig { params(original: T.untyped).returns(T.untyped) }
      def self.initialize_copy(original); end

      module Scoped
        # This is called when a field has `scope: true`.
        # The field's return type class receives this call.
        # 
        # By default, it's a no-op. Override it to scope your objects.
        # 
        # _@param_ `items` — Some list-like object (eg, Array, ActiveRecord::Relation)
        # 
        # _@param_ `context` — 
        # 
        # _@return_ — Another list-like object, scoped to the current context
        sig { params(items: T.untyped, context: GraphQL::Query::Context).returns(T.untyped) }
        def scope_items(items, context); end
      end

      module HasPath
        # _@return_ — A description of this member's place in the GraphQL schema
        sig { returns(String) }
        def path; end
      end

      # @api private
      module BuildType
        LIST_TYPE_ERROR = T.let("Use an array of [T] or [T, null: true] for list types; other arrays are not supported", T.untyped)

        # _@param_ `type_expr`
        sig { params(type_expr: T.any(String, Class, GraphQL::BaseType), null: T.untyped).returns(GraphQL::BaseType) }
        def parse_type(type_expr, null:); end

        # _@param_ `type_expr` — 
        sig { params(type_expr: T.any(String, Class, GraphQL::BaseType), null: T.untyped).returns(GraphQL::BaseType) }
        def self.parse_type(type_expr, null:); end

        sig { params(something: T.untyped).returns(T.untyped) }
        def to_type_name(something); end

        sig { params(something: T.untyped).returns(T.untyped) }
        def self.to_type_name(something); end

        sig { params(string: T.untyped).returns(T.untyped) }
        def camelize(string); end

        sig { params(string: T.untyped).returns(T.untyped) }
        def self.camelize(string); end

        # Resolves constant from string (based on Rails `ActiveSupport::Inflector.constantize`)
        sig { params(string: T.untyped).returns(T.untyped) }
        def constantize(string); end

        # Resolves constant from string (based on Rails `ActiveSupport::Inflector.constantize`)
        sig { params(string: T.untyped).returns(T.untyped) }
        def self.constantize(string); end

        sig { params(string: T.untyped).returns(T.untyped) }
        def underscore(string); end

        sig { params(string: T.untyped).returns(T.untyped) }
        def self.underscore(string); end
      end

      # Shared code for Object and Interface
      module HasFields
        CONFLICT_FIELD_NAMES = T.let(Set.new([
  # GraphQL-Ruby conflicts
  :context, :object,
  # Ruby built-ins conflicts
  :method, :class
]), T.untyped)

        # Add a field to this object or interface with the given definition
        # 
        # _@see_ `{GraphQL::Schema::Field#initialize}` — for method signature
        sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(GraphQL::Schema::Field) }
        def field(*args, **kwargs, &block); end

        # _@return_ — Fields on this object, keyed by name, including inherited fields
        sig { returns(T::Hash[String, GraphQL::Schema::Field]) }
        def fields; end

        sig { params(field_name: T.untyped).returns(T.untyped) }
        def get_field(field_name); end

        # Register this field with the class, overriding a previous one if needed.
        # 
        # _@param_ `field_defn` — 
        sig { params(field_defn: GraphQL::Schema::Field).void }
        def add_field(field_defn); end

        # _@return_ — The class to initialize when adding fields to this kind of schema member
        sig { params(new_field_class: T.untyped).returns(Class) }
        def field_class(new_field_class = nil); end

        sig { params(field_name: T.untyped).returns(T.untyped) }
        def global_id_field(field_name); end

        # _@return_ — Fields defined on this class _specifically_, not parent classes
        sig { returns(T::Array[GraphQL::Schema::Field]) }
        def own_fields; end
      end

      module HasAstNode
        # If this schema was parsed from a `.graphql` file (or other SDL),
        # this is the AST node that defined this part of the schema.
        sig { params(new_ast_node: T.untyped).returns(T.untyped) }
        def ast_node(new_ast_node = nil); end
      end

      module HasArguments
        sig { params(cls: T.untyped).returns(T.untyped) }
        def self.included(cls); end

        sig { params(cls: T.untyped).returns(T.untyped) }
        def self.extended(cls); end

        # _@return_ — An instance of {arguments_class}, created from `*args`
        # 
        # _@see_ `{GraphQL::Schema::Argument#initialize}` — for parameters
        sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(GraphQL::Schema::Argument) }
        def argument(*args, **kwargs, &block); end

        # Register this argument with the class.
        # 
        # _@param_ `arg_defn` — 
        sig { params(arg_defn: GraphQL::Schema::Argument).returns(GraphQL::Schema::Argument) }
        def add_argument(arg_defn); end

        # _@return_ — Hash<String => GraphQL::Schema::Argument] Arguments defined on this thing, keyed by name. Includes inherited definitions
        sig { returns(T.untyped) }
        def arguments; end

        # _@param_ `new_arg_class` — A class to use for building argument definitions
        sig { params(new_arg_class: T.nilable(Class)).returns(T.untyped) }
        def argument_class(new_arg_class = nil); end

        sig { returns(T.untyped) }
        def own_arguments; end

        module ArgumentClassAccessor
          sig { params(new_arg_class: T.untyped).returns(T.untyped) }
          def argument_class(new_arg_class = nil); end
        end

        module ArgumentObjectLoader
          # Look up the corresponding object for a provided ID.
          # By default, it uses Relay-style {Schema.object_from_id},
          # override this to find objects another way.
          # 
          # _@param_ `type` — A GraphQL type definition
          # 
          # _@param_ `id` — A client-provided to look up
          # 
          # _@param_ `context` — the current context
          sig { params(type: T.any(Class, Module), id: String, context: GraphQL::Query::Context).returns(T.untyped) }
          def object_from_id(type, id, context); end

          sig { params(argument: T.untyped, lookup_as_type: T.untyped, id: T.untyped).returns(T.untyped) }
          def load_application_object(argument, lookup_as_type, id); end

          sig { params(err: T.untyped).returns(T.untyped) }
          def load_application_object_failed(err); end
        end
      end

      module Instrumentation
        sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
        def instrument(type, field); end

        sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
        def self.instrument(type, field); end

        sig { params(query: T.untyped).returns(T.untyped) }
        def before_query(query); end

        sig { params(query: T.untyped).returns(T.untyped) }
        def self.before_query(query); end

        sig { params(_query: T.untyped).returns(T.untyped) }
        def after_query(_query); end

        sig { params(_query: T.untyped).returns(T.untyped) }
        def self.after_query(_query); end

        sig { params(field: T.untyped).returns(T.untyped) }
        def apply_proxy(field); end

        sig { params(field: T.untyped).returns(T.untyped) }
        def self.apply_proxy(field); end

        sig { params(type: T.untyped, starting_at: T.untyped).returns(T.untyped) }
        def list_depth(type, starting_at = 0); end

        sig { params(type: T.untyped, starting_at: T.untyped).returns(T.untyped) }
        def self.list_depth(type, starting_at = 0); end

        class ProxiedResolve
          sig { params(inner_resolve: T.untyped, list_depth: T.untyped, inner_return_type: T.untyped).returns(ProxiedResolve) }
          def initialize(inner_resolve:, list_depth:, inner_return_type:); end

          sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
          def call(obj, args, ctx); end

          sig { params(inner_obj: T.untyped, depth: T.untyped, ctx: T.untyped).returns(T.untyped) }
          def proxy_to_depth(inner_obj, depth, ctx); end
        end
      end

      module RelayShortcuts
        sig { params(new_edge_type_class: T.untyped).returns(T.untyped) }
        def edge_type_class(new_edge_type_class = nil); end

        sig { params(new_connection_type_class: T.untyped).returns(T.untyped) }
        def connection_type_class(new_connection_type_class = nil); end

        sig { returns(T.untyped) }
        def edge_type; end

        sig { returns(T.untyped) }
        def connection_type; end
      end

      # DSL methods shared by lots of things in the GraphQL Schema.
      # @api private
      # @see Classes that extend this, eg {GraphQL::Schema::Object}
      module BaseDSLMethods
        include GraphQL::Schema::FindInheritedValue

        # Call this with a new name to override the default name for this schema member; OR
        # call it without an argument to get the name of this schema member
        # 
        # The default name is implemented in default_graphql_name
        # 
        # _@param_ `new_name` — 
        sig { params(new_name: T.nilable(String)).returns(String) }
        def graphql_name(new_name = nil); end

        # Just a convenience method to point out that people should use graphql_name instead
        sig { params(new_name: T.untyped).returns(T.untyped) }
        def name(new_name = nil); end

        # Call this method to provide a new description; OR
        # call it without an argument to get the description
        # 
        # _@param_ `new_description` — 
        sig { params(new_description: T.nilable(String)).returns(String) }
        def description(new_description = nil); end

        # _@return_ — If true, this object is part of the introspection system
        sig { params(new_introspection: T.untyped).returns(T::Boolean) }
        def introspection(new_introspection = nil); end

        sig { returns(T::Boolean) }
        def introspection?; end

        # The mutation this type was derived from, if it was derived from a mutation
        sig { params(mutation_class: T.untyped).returns(Class) }
        def mutation(mutation_class = nil); end

        # _@return_ — Convert this type to a legacy-style object.
        sig { returns(GraphQL::BaseType) }
        def to_graphql; end

        sig { returns(T.untyped) }
        def overridden_graphql_name; end

        # Creates the default name for a schema member.
        # The default name is the Ruby constant name,
        # without any namespaces and with any `-Type` suffix removed
        sig { returns(T.untyped) }
        def default_graphql_name; end

        sig { params(context: T.untyped).returns(T::Boolean) }
        def visible?(context); end

        sig { params(context: T.untyped).returns(T::Boolean) }
        def accessible?(context); end

        sig { params(object: T.untyped, context: T.untyped).returns(T::Boolean) }
        def authorized?(object, context); end

        sig { params(method_name: T.untyped, default_value: T.untyped).returns(T.untyped) }
        def find_inherited_value(method_name, default_value = nil); end
      end

      # Support for legacy `accepts_definitions` functions.
      # 
      # Keep the legacy handler hooked up. Class-based types and fields
      # will call those legacy handlers during their `.to_graphql`
      # methods.
      # 
      # This can help out while transitioning from one to the other.
      # Eventually, `GraphQL::{X}Type` objects will be removed entirely,
      # But this can help during the transition.
      # 
      # @example Applying a function to base object class
      #   # Here's the legacy-style config, which we're calling back to:
      #   GraphQL::ObjectType.accepts_definition({
      #     permission_level: ->(defn, value) { defn.metadata[:permission_level] = value }
      #   })
      # 
      #   class BaseObject < GraphQL::Schema::Object
      #     # Setup a named pass-through to the legacy config functions
      #     accepts_definition :permission_level
      #   end
      # 
      #   class Account < BaseObject
      #     # This value will be passed to the legacy handler:
      #     permission_level 1
      #   end
      # 
      #   # The class gets a reader method which returns the args,
      #   # only marginally useful.
      #   Account.permission_level # => [1]
      # 
      #   # The legacy handler is called, as before:
      #   Account.graphql_definition.metadata[:permission_level] # => 1
      module AcceptsDefinition
        sig { params(child: T.untyped).returns(T.untyped) }
        def self.included(child); end

        sig { params(child: T.untyped).returns(T.untyped) }
        def self.extended(child); end

        module AcceptsDefinitionDefinitionMethods
          sig { params(name: T.untyped).returns(T.untyped) }
          def accepts_definition(name); end

          sig { returns(T.untyped) }
          def accepts_definition_methods; end

          sig { returns(T.untyped) }
          def own_accepts_definition_methods; end
        end

        module ToGraphQLExtension
          sig { returns(T.untyped) }
          def to_graphql; end
        end

        module InitializeExtension
          sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(T.untyped) }
          def initialize(*args, **kwargs, &block); end

          sig { returns(T.untyped) }
          def accepts_definition_methods; end
        end
      end

      # These constants are interpreted as GraphQL types when defining fields or arguments
      # 
      # @example
      #   field :is_draft, Boolean, null: false
      #   field :id, ID, null: false
      #   field :score, Int, null: false
      # 
      # @api private
      module GraphQLTypeNames
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)
      end

      module TypeSystemHelpers
        # _@return_ — Make a non-null-type representation of this type
        sig { returns(Schema::NonNull) }
        def to_non_null_type; end

        # _@return_ — Make a list-type representation of this type
        sig { returns(Schema::List) }
        def to_list_type; end

        # _@return_ — true if this is a non-nullable type. A nullable list of non-nullables is considered nullable.
        sig { returns(T::Boolean) }
        def non_null?; end

        # _@return_ — true if this is a list type. A non-nullable list is considered a list.
        sig { returns(T::Boolean) }
        def list?; end

        sig { returns(T.untyped) }
        def to_type_signature; end

        sig { returns(GraphQL::TypeKinds::TypeKind) }
        def kind; end
      end

      # Adds a layer of caching over user-supplied `.to_graphql` methods.
      # Users override `.to_graphql`, but all runtime code should use `.graphql_definition`.
      # @api private
      # @see concrete classes that extend this, eg {Schema::Object}
      module CachedGraphQLDefinition
        # A cached result of {.to_graphql}.
        # It's cached here so that user-overridden {.to_graphql} implementations
        # are also cached
        sig { returns(T.untyped) }
        def graphql_definition; end

        # This is for a common interface with .define-based types
        sig { returns(T.untyped) }
        def type_class; end

        # Wipe out the cached graphql_definition so that `.to_graphql` will be called again.
        sig { params(original: T.untyped).returns(T.untyped) }
        def initialize_copy(original); end
      end
    end

    class Object < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend GraphQL::Schema::Member::HasFields
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # _@return_ — the application object this type is wrapping
      sig { returns(Object) }
      def object; end

      # _@return_ — the context instance for this query
      sig { returns(GraphQL::Query::Context) }
      def context; end

      # Make a new instance of this type _if_ the auth check passes,
      # otherwise, raise an error.
      # 
      # Probably only the framework should call this method.
      # 
      # This might return a {GraphQL::Execution::Lazy} if the user-provided `.authorized?`
      # hook returns some lazy value (like a Promise).
      # 
      # The reason that the auth check is in this wrapper method instead of {.new} is because
      # of how it might return a Promise. It would be weird if `.new` returned a promise;
      # It would be a headache to try to maintain Promise-y state inside a {Schema::Object}
      # instance. So, hopefully this wrapper method will do the job.
      # 
      # _@param_ `object` — The thing wrapped by this object
      # 
      # _@param_ `context` — 
      sig { params(object: Object, context: GraphQL::Query::Context).returns(T.any(GraphQL::Schema::Object, GraphQL::Execution::Lazy)) }
      def self.authorized_new(object, context); end

      sig { params(object: T.untyped, context: T.untyped).returns(Object) }
      def initialize(object, context); end

      sig { params(new_interfaces: T.untyped).returns(T.untyped) }
      def self.implements(*new_interfaces); end

      sig { returns(T.untyped) }
      def self.interfaces; end

      sig { returns(T.untyped) }
      def self.own_interfaces; end

      # Include legacy-style interfaces, too
      sig { returns(T.untyped) }
      def self.fields; end

      sig { returns(GraphQL::ObjectType) }
      def self.to_graphql; end

      sig { returns(T.untyped) }
      def self.kind; end

      # Add a field to this object or interface with the given definition
      # 
      # _@see_ `{GraphQL::Schema::Field#initialize}` — for method signature
      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(GraphQL::Schema::Field) }
      def self.field(*args, **kwargs, &block); end

      sig { params(field_name: T.untyped).returns(T.untyped) }
      def self.get_field(field_name); end

      # Register this field with the class, overriding a previous one if needed.
      # 
      # _@param_ `field_defn` — 
      sig { params(field_defn: GraphQL::Schema::Field).void }
      def self.add_field(field_defn); end

      # _@return_ — The class to initialize when adding fields to this kind of schema member
      sig { params(new_field_class: T.untyped).returns(Class) }
      def self.field_class(new_field_class = nil); end

      sig { params(field_name: T.untyped).returns(T.untyped) }
      def self.global_id_field(field_name); end

      # _@return_ — Fields defined on this class _specifically_, not parent classes
      sig { returns(T::Array[GraphQL::Schema::Field]) }
      def self.own_fields; end
    end

    class Scalar < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend Forwardable
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(val: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.coerce_input(val, ctx); end

      sig { params(val: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(val, ctx); end

      sig { returns(T.untyped) }
      def self.to_graphql; end

      sig { returns(T.untyped) }
      def self.kind; end

      sig { params(is_default: T.untyped).returns(T.untyped) }
      def self.default_scalar(is_default = nil); end
    end

    # Restrict access to a {GraphQL::Schema} with a user-defined filter.
    # 
    # When validating and executing a query, all access to schema members
    # should go through a warden. If you access the schema directly,
    # you may show a client something that it shouldn't be allowed to see.
    # 
    # @example Hidding private fields
    #   private_members = -> (member, ctx) { member.metadata[:private] }
    #   result = Schema.execute(query_string, except: private_members)
    # 
    # @example Custom filter implementation
    #   # It must respond to `#call(member)`.
    #   class MissingRequiredFlags
    #     def initialize(user)
    #       @user = user
    #     end
    # 
    #     # Return `false` if any required flags are missing
    #     def call(member, ctx)
    #       member.metadata[:required_flags].any? do |flag|
    #         !@user.has_flag?(flag)
    #       end
    #     end
    #   end
    # 
    #   # Then, use the custom filter in query:
    #   missing_required_flags = MissingRequiredFlags.new(current_user)
    # 
    #   # This query can only access members which match the user's flags
    #   result = Schema.execute(query_string, except: missing_required_flags)
    # 
    # @api private
    class Warden
      # _@param_ `filter` — Objects are hidden when `.call(member, ctx)` returns true
      # 
      # _@param_ `context` — 
      # 
      # _@param_ `schema` — 
      # 
      # _@param_ `deep_check` — 
      sig { params(filter: T::Array[T.untyped], context: GraphQL::Query::Context, schema: GraphQL::Schema).returns(Warden) }
      def initialize(filter, context:, schema:); end

      # _@return_ — Visible types in the schema
      sig { returns(T::Array[GraphQL::BaseType]) }
      def types; end

      # _@return_ — The type named `type_name`, if it exists (else `nil`)
      sig { params(type_name: T.untyped).returns(T.nilable(GraphQL::BaseType)) }
      def get_type(type_name); end

      # _@return_ — The field named `field_name` on `parent_type`, if it exists
      sig { params(parent_type: T.untyped, field_name: T.untyped).returns(T.nilable(GraphQL::Field)) }
      def get_field(parent_type, field_name); end

      # _@return_ — The types which may be member of `type_defn`
      sig { params(type_defn: T.untyped).returns(T::Array[GraphQL::BaseType]) }
      def possible_types(type_defn); end

      # _@param_ `type_defn` — 
      # 
      # _@return_ — Fields on `type_defn`
      sig { params(type_defn: T.any(GraphQL::ObjectType, GraphQL::InterfaceType)).returns(T::Array[GraphQL::Field]) }
      def fields(type_defn); end

      # _@param_ `argument_owner` — 
      # 
      # _@return_ — Visible arguments on `argument_owner`
      sig { params(argument_owner: T.any(GraphQL::Field, GraphQL::InputObjectType)).returns(T::Array[GraphQL::Argument]) }
      def arguments(argument_owner); end

      # _@return_ — Visible members of `enum_defn`
      sig { params(enum_defn: T.untyped).returns(T::Array[GraphQL::EnumType::EnumValue]) }
      def enum_values(enum_defn); end

      # _@return_ — Visible interfaces implemented by `obj_type`
      sig { params(obj_type: T.untyped).returns(T::Array[GraphQL::InterfaceType]) }
      def interfaces(obj_type); end

      sig { returns(T.untyped) }
      def directives; end

      sig { params(op_name: T.untyped).returns(T.untyped) }
      def root_type_for_operation(op_name); end

      sig { params(obj_type: T.untyped).returns(T.untyped) }
      def union_memberships(obj_type); end

      sig { params(field_defn: T.untyped).returns(T::Boolean) }
      def visible_field?(field_defn); end

      sig { params(type_defn: T.untyped).returns(T::Boolean) }
      def visible_type?(type_defn); end

      sig { params(type_defn: T.untyped).returns(T::Boolean) }
      def root_type?(type_defn); end

      sig { params(type_defn: T.untyped).returns(T::Boolean) }
      def referenced?(type_defn); end

      sig { params(type_defn: T.untyped).returns(T::Boolean) }
      def orphan_type?(type_defn); end

      sig { params(type_defn: T.untyped).returns(T::Boolean) }
      def visible_abstract_type?(type_defn); end

      sig { params(type_defn: T.untyped).returns(T::Boolean) }
      def visible_possible_types?(type_defn); end

      sig { params(member: T.untyped).returns(T::Boolean) }
      def visible?(member); end

      sig { returns(T.untyped) }
      def read_through; end
    end

    # Used to convert your {GraphQL::Schema} to a GraphQL schema string
    # 
    # @example print your schema to standard output (via helper)
    #   MySchema = GraphQL::Schema.define(query: QueryType)
    #   puts GraphQL::Schema::Printer.print_schema(MySchema)
    # 
    # @example print your schema to standard output
    #   MySchema = GraphQL::Schema.define(query: QueryType)
    #   puts GraphQL::Schema::Printer.new(MySchema).print_schema
    # 
    # @example print a single type to standard output
    #   query_root = GraphQL::ObjectType.define do
    #     name "Query"
    #     description "The query root of this schema"
    # 
    #     field :post do
    #       type post_type
    #       resolve ->(obj, args, ctx) { Post.find(args["id"]) }
    #     end
    #   end
    # 
    #   post_type = GraphQL::ObjectType.define do
    #     name "Post"
    #     description "A blog post"
    # 
    #     field :id, !types.ID
    #     field :title, !types.String
    #     field :body, !types.String
    #   end
    # 
    #   MySchema = GraphQL::Schema.define(query: query_root)
    # 
    #   printer = GraphQL::Schema::Printer.new(MySchema)
    #   puts printer.print_type(post_type)
    class Printer < GraphQL::Language::Printer
      # Returns the value of attribute schema
      sig { returns(T.untyped) }
      def schema; end

      # Returns the value of attribute warden
      sig { returns(T.untyped) }
      def warden; end

      # _@param_ `schema` — 
      # 
      # _@param_ `context` — 
      # 
      # _@param_ `only` — 
      # 
      # _@param_ `except` — 
      # 
      # _@param_ `introspection` — Should include the introspection types in the string?
      sig do
        params(
          schema: GraphQL::Schema,
          context: T.nilable(T::Hash[T.untyped, T.untyped]),
          only: T.nilable(T::Array[T.untyped]),
          except: T.nilable(T::Array[T.untyped]),
          introspection: T::Boolean
        ).returns(Printer)
      end
      def initialize(schema, context: nil, only: nil, except: nil, introspection: false); end

      # Return the GraphQL schema string for the introspection type system
      sig { returns(T.untyped) }
      def self.print_introspection_schema; end

      # Return a GraphQL schema string for the defined types in the schema
      # 
      # _@param_ `schema` — 
      # 
      # _@param_ `context` — 
      # 
      # _@param_ `only` — 
      # 
      # _@param_ `except` — 
      sig { params(schema: GraphQL::Schema, args: T.untyped).returns(T.untyped) }
      def self.print_schema(schema, **args); end

      # Return a GraphQL schema string for the defined types in the schema
      sig { returns(T.untyped) }
      def print_schema; end

      sig { params(type: T.untyped).returns(T.untyped) }
      def print_type(type); end

      sig { params(directive: T.untyped).returns(T.untyped) }
      def print_directive(directive); end

      class IntrospectionPrinter < GraphQL::Language::Printer
        sig { params(schema: T.untyped).returns(T.untyped) }
        def print_schema_definition(schema); end
      end
    end

    # This plugin will stop resolving new fields after `max_seconds` have elapsed.
    # After the time has passed, any remaining fields will be `nil`, with errors added
    # to the `errors` key. Any already-resolved fields will be in the `data` key, so
    # you'll get a partial response.
    # 
    # You can subclass `GraphQL::Schema::Timeout` and override the `handle_timeout` method
    # to provide custom logic when a timeout error occurs.
    # 
    # Note that this will stop a query _in between_ field resolutions, but
    # it doesn't interrupt long-running `resolve` functions. Be sure to use
    # timeout options for external connections. For more info, see
    # www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/
    # 
    # @example Stop resolving fields after 2 seconds
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Schema::Timeout, max_seconds: 2
    #   end
    # 
    # @example Notifying Bugsnag and logging a timeout
    #   class MyTimeout < GraphQL::Schema::Timeout
    #     def handle_timeout(error, query)
    #        Rails.logger.warn("GraphQL Timeout: #{error.message}: #{query.query_string}")
    #        Bugsnag.notify(error, {query_string: query.query_string})
    #     end
    #   end
    # 
    #   class MySchema < GraphQL::Schema
    #     use MyTimeout, max_seconds: 2
    #   end
    class Timeout
      # Returns the value of attribute max_seconds
      sig { returns(T.untyped) }
      def max_seconds; end

      sig { params(schema: T.untyped, options: T.untyped).returns(T.untyped) }
      def self.use(schema, **options); end

      # _@param_ `max_seconds` — how many seconds the query should be allowed to resolve new fields
      sig { params(max_seconds: Numeric).returns(Timeout) }
      def initialize(max_seconds:); end

      sig { params(key: T.untyped, data: T.untyped).returns(T.untyped) }
      def trace(key, data); end

      # Invoked when a query times out.
      # 
      # _@param_ `error` — 
      # 
      # _@param_ `query` — 
      sig { params(error: GraphQL::Schema::Timeout::TimeoutError, query: GraphQL::Error).returns(T.untyped) }
      def handle_timeout(error, query); end

      # This error is raised when a query exceeds `max_seconds`.
      # Since it's a child of {GraphQL::ExecutionError},
      # its message will be added to the response's `errors` key.
      # 
      # To raise an error that will stop query resolution, use a custom block
      # to take this error and raise a new one which _doesn't_ descend from {GraphQL::ExecutionError},
      # such as `RuntimeError`.
      class TimeoutError < GraphQL::ExecutionError
        sig { params(parent_type: T.untyped, field: T.untyped).returns(TimeoutError) }
        def initialize(parent_type, field); end
      end
    end

    class Wrapper
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::TypeSystemHelpers

      # _@return_ — The inner type of this wrapping type, the type of which one or more objects may be present.
      sig { returns(T.any(Class, Module)) }
      def of_type; end

      sig { params(of_type: T.untyped).returns(Wrapper) }
      def initialize(of_type); end

      sig { returns(T.untyped) }
      def to_graphql; end

      sig { returns(T.untyped) }
      def unwrap; end

      sig { params(other: T.untyped).returns(T.untyped) }
      def ==(other); end

      # _@return_ — Make a non-null-type representation of this type
      sig { returns(Schema::NonNull) }
      def to_non_null_type; end

      # _@return_ — Make a list-type representation of this type
      sig { returns(Schema::List) }
      def to_list_type; end

      # _@return_ — true if this is a non-nullable type. A nullable list of non-nullables is considered nullable.
      sig { returns(T::Boolean) }
      def non_null?; end

      # _@return_ — true if this is a list type. A non-nullable list is considered a list.
      sig { returns(T::Boolean) }
      def list?; end

      sig { returns(T.untyped) }
      def to_type_signature; end

      sig { returns(GraphQL::TypeKinds::TypeKind) }
      def kind; end

      # A cached result of {.to_graphql}.
      # It's cached here so that user-overridden {.to_graphql} implementations
      # are also cached
      sig { returns(T.untyped) }
      def graphql_definition; end

      # This is for a common interface with .define-based types
      sig { returns(T.untyped) }
      def type_class; end

      # Wipe out the cached graphql_definition so that `.to_graphql` will be called again.
      sig { params(original: T.untyped).returns(T.untyped) }
      def initialize_copy(original); end
    end

    class Argument
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::AcceptsDefinition
      include GraphQL::Schema::Member::HasPath
      include GraphQL::Schema::Member::HasAstNode
      NO_DEFAULT = T.let(:__no_default__, T.untyped)

      # _@return_ — the GraphQL name for this argument, camelized unless `camelize: false` is provided
      sig { returns(String) }
      def name; end

      # _@return_ — The field or input object this argument belongs to
      sig { returns(T.any(GraphQL::Schema::Field, Class)) }
      def owner; end

      # _@return_ — A method to call to transform this value before sending it to field resolution method
      sig { returns(Symbol) }
      def prepare; end

      # _@return_ — This argument's name in Ruby keyword arguments
      sig { returns(Symbol) }
      def keyword; end

      # _@return_ — If this argument should load an application object, this is the type of object to load
      sig { returns(T.nilable(T.any(Class, Module))) }
      def loads; end

      # _@return_ — true if a resolver defined this argument
      sig { returns(T::Boolean) }
      def from_resolver?; end

      # _@param_ `arg_name` — 
      # 
      # _@param_ `type_expr`
      # 
      # _@param_ `desc` — 
      # 
      # _@param_ `required` — if true, this argument is non-null; if false, this argument is nullable
      # 
      # _@param_ `description` — 
      # 
      # _@param_ `default_value` — 
      # 
      # _@param_ `as` — Override the keyword name when passed to a method
      # 
      # _@param_ `prepare` — A method to call to transform this argument's valuebefore sending it to field resolution
      # 
      # _@param_ `camelize` — if true, the name will be camelized when building the schema
      # 
      # _@param_ `from_resolver` — if true, a Resolver class defined this argument
      # 
      # _@param_ `method_access` — If false, don't build method access on legacy {Query::Arguments} instances.
      sig do
        params(
          type_expr: T.untyped,
          arg_name: T.nilable(Symbol),
          desc: T.nilable(String),
          required: T::Boolean,
          owner: T.untyped,
          default_value: T.untyped,
          as: T.nilable(Symbol),
          from_resolver: T::Boolean,
          camelize: T::Boolean,
          prepare: T.nilable(Symbol),
          method_access: T::Boolean,
          ast_node: T.untyped,
          type: T.untyped,
          name: T.untyped,
          loads: T.untyped,
          description: T.nilable(String),
          definition_block: T.untyped
        ).returns(Argument)
      end
      def initialize(type_expr = nil, arg_name = nil, desc = nil, required:, owner:, default_value: NO_DEFAULT, as: nil, from_resolver: false, camelize: true, prepare: nil, method_access: true, ast_node: nil, type: nil, name: nil, loads: nil, description: nil, &definition_block); end

      # _@return_ — the value used when the client doesn't provide a value for this argument
      sig { returns(T.untyped) }
      def default_value; end

      # _@return_ — True if this argument has a default value
      sig { returns(T::Boolean) }
      def default_value?; end

      # Sets the attribute description
      # 
      # _@param_ `value` — the value to set the attribute description to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def description=(value); end

      # _@return_ — Documentation for this argument
      sig { params(text: T.untyped).returns(String) }
      def description(text = nil); end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def visible?(context); end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def accessible?(context); end

      sig { params(obj: T.untyped, value: T.untyped, ctx: T.untyped).returns(T::Boolean) }
      def authorized?(obj, value, ctx); end

      sig do
        params(
          obj: T.untyped,
          value: T.untyped,
          ctx: T.untyped,
          as_type: T.untyped
        ).returns(T::Boolean)
      end
      def authorized_as_type?(obj, value, ctx, as_type:); end

      sig { returns(T.untyped) }
      def to_graphql; end

      sig { returns(T.untyped) }
      def type; end

      # Apply the {prepare} configuration to `value`, using methods from `obj`.
      # Used by the runtime.
      sig { params(obj: T.untyped, value: T.untyped).returns(T.untyped) }
      def prepare_value(obj, value); end

      # If this schema was parsed from a `.graphql` file (or other SDL),
      # this is the AST node that defined this part of the schema.
      sig { params(new_ast_node: T.untyped).returns(T.untyped) }
      def ast_node(new_ast_node = nil); end

      # _@return_ — A description of this member's place in the GraphQL schema
      sig { returns(String) }
      def path; end

      # A cached result of {.to_graphql}.
      # It's cached here so that user-overridden {.to_graphql} implementations
      # are also cached
      sig { returns(T.untyped) }
      def graphql_definition; end

      # This is for a common interface with .define-based types
      sig { returns(T.untyped) }
      def type_class; end

      # Wipe out the cached graphql_definition so that `.to_graphql` will be called again.
      sig { params(original: T.untyped).returns(T.untyped) }
      def initialize_copy(original); end
    end

    # This base class accepts configuration for a mutation root field,
    # then it can be hooked up to your mutation root object type.
    # 
    # If you want to customize how this class generates types, in your base class,
    # override the various `generate_*` methods.
    # 
    # @see {GraphQL::Schema::RelayClassicMutation} for an extension of this class with some conventions built-in.
    # 
    # @example Creating a comment
    #  # Define the mutation:
    #  class Mutations::CreateComment < GraphQL::Schema::Mutation
    #    argument :body, String, required: true
    #    argument :post_id, ID, required: true
    # 
    #    field :comment, Types::Comment, null: true
    #    field :errors, [String], null: false
    # 
    #    def resolve(body:, post_id:)
    #      post = Post.find(post_id)
    #      comment = post.comments.build(body: body, author: context[:current_user])
    #      if comment.save
    #        # Successful creation, return the created object with no errors
    #        {
    #          comment: comment,
    #          errors: [],
    #        }
    #      else
    #        # Failed save, return the errors to the client
    #        {
    #          comment: nil,
    #          errors: comment.errors.full_messages
    #        }
    #      end
    #    end
    #  end
    # 
    #  # Hook it up to your mutation:
    #  class Types::Mutation < GraphQL::Schema::Object
    #    field :create_comment, mutation: Mutations::CreateComment
    #  end
    # 
    #  # Call it from GraphQL:
    #  result = MySchema.execute <<-GRAPHQL
    #  mutation {
    #    createComment(postId: "1", body: "Nice Post!") {
    #      errors
    #      comment {
    #        body
    #        author {
    #          login
    #        }
    #      }
    #    }
    #  }
    #  GRAPHQL
    class Mutation < GraphQL::Schema::Resolver
      extend GraphQL::Schema::Member::HasFields
      extend GraphQL::Schema::Resolver::HasPayloadType
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # Override this method to handle legacy-style usages of `MyMutation.field`
      sig { params(args: T.untyped, block: T.untyped).returns(T.untyped) }
      def self.field(*args, &block); end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def self.visible?(context); end

      # Override this to attach self as `mutation`
      sig { returns(T.untyped) }
      def self.generate_payload_type; end

      # Call this method to get the derived return type of the mutation,
      # or use it as a configuration method to assign a return type
      # instead of generating one.
      # 
      # _@param_ `new_payload_type` — If a type definition class is provided, it will be used as the return type of the mutation field
      # 
      # _@return_ — The object type which this mutation returns.
      sig { params(new_payload_type: T.nilable(Class)).returns(Class) }
      def self.payload_type(new_payload_type = nil); end

      sig { params(new_class: T.untyped).returns(T.untyped) }
      def self.field_class(new_class = nil); end

      # An object class to use for deriving return types
      # 
      # _@param_ `new_class` — Defaults to {GraphQL::Schema::Object}
      sig { params(new_class: T.nilable(Class)).returns(Class) }
      def self.object_class(new_class = nil); end

      # _@return_ — Fields on this object, keyed by name, including inherited fields
      sig { returns(T::Hash[String, GraphQL::Schema::Field]) }
      def self.fields; end

      sig { params(field_name: T.untyped).returns(T.untyped) }
      def self.get_field(field_name); end

      # Register this field with the class, overriding a previous one if needed.
      # 
      # _@param_ `field_defn` — 
      sig { params(field_defn: GraphQL::Schema::Field).void }
      def self.add_field(field_defn); end

      sig { params(field_name: T.untyped).returns(T.untyped) }
      def self.global_id_field(field_name); end

      # _@return_ — Fields defined on this class _specifically_, not parent classes
      sig { returns(T::Array[GraphQL::Schema::Field]) }
      def self.own_fields; end
    end

    # Represents a non null type in the schema.
    # Wraps a {Schema::Member} when it is required.
    # @see {Schema::Member::TypeSystemHelpers#to_non_null_type}
    class NonNull < GraphQL::Schema::Wrapper
      sig { returns(T.untyped) }
      def to_graphql; end

      sig { returns(T.untyped) }
      def kind; end

      sig { returns(T::Boolean) }
      def non_null?; end

      # _@return_ — True if this type wraps a list type
      sig { returns(T::Boolean) }
      def list?; end

      sig { returns(T.untyped) }
      def to_type_signature; end

      sig { returns(T.untyped) }
      def inspect; end
    end

    # A class-based container for field configuration and resolution logic. It supports:
    # 
    # - Arguments, via `.argument(...)` helper, which will be applied to the field.
    # - Return type, via `.type(..., null: ...)`, which will be applied to the field.
    # - Description, via `.description(...)`, which will be applied to the field
    # - Resolution, via `#resolve(**args)` method, which will be called to resolve the field.
    # - `#object` and `#context` accessors for use during `#resolve`.
    # 
    # Resolvers can be attached with the `resolver:` option in a `field(...)` call.
    # 
    # A resolver's configuration may be overridden with other keywords in the `field(...)` call.
    # 
    # See the {.field_options} to see how a Resolver becomes a set of field configuration options.
    # 
    # @see {GraphQL::Schema::Mutation} for a concrete subclass of `Resolver`.
    # @see {GraphQL::Function} `Resolver` is a replacement for `GraphQL::Function`
    class Resolver
      include GraphQL::Schema::Member::GraphQLTypeNames
      include GraphQL::Schema::Member::HasPath
      extend GraphQL::Schema::Member::BaseDSLMethods
      extend GraphQL::Schema::Member::HasArguments
      extend GraphQL::Schema::Member::HasPath
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # _@param_ `object` — the initialize object, pass to {Query.initialize} as `root_value`
      # 
      # _@param_ `context` — 
      sig { params(object: T.untyped, context: GraphQL::Query::Context).returns(Resolver) }
      def initialize(object:, context:); end

      # _@return_ — The application object this field is being resolved on
      sig { returns(T.untyped) }
      def object; end

      sig { returns(GraphQL::Query::Context) }
      def context; end

      # This method is _actually_ called by the runtime,
      # it does some preparation and then eventually calls
      # the user-defined `#resolve` method.
      sig { params(args: T.untyped).returns(T.untyped) }
      def resolve_with_support(**args); end

      # Do the work. Everything happens here.
      # 
      # _@return_ — An object corresponding to the return type
      sig { params(args: T.untyped).returns(T.untyped) }
      def resolve(**args); end

      # Called before arguments are prepared.
      # Implement this hook to make checks before doing any work.
      # 
      # If it returns a lazy object (like a promise), it will be synced by GraphQL
      # (but the resulting value won't be used).
      # 
      # _@param_ `args` — The input arguments, if there are any
      # 
      # _@return_ — If `false`, execution will stop (and `early_return_data` will be returned instead, if present.)
      sig { params(args: T::Hash[T.untyped, T.untyped]).returns(T.any(T::Boolean, T.untyped)) }
      def ready?(**args); end

      # Called after arguments are loaded, but before resolving.
      # 
      # Override it to check everything before calling the mutation.
      # 
      # _@param_ `inputs` — The input arguments
      # 
      # _@return_ — If `false`, execution will stop (and `early_return_data` will be returned instead, if present.)
      sig { params(inputs: T::Hash[T.untyped, T.untyped]).returns(T.any(T::Boolean, T.untyped)) }
      def authorized?(**inputs); end

      sig { params(args: T.untyped).returns(T.untyped) }
      def load_arguments(args); end

      sig { params(name: T.untyped, value: T.untyped).returns(T.untyped) }
      def load_argument(name, value); end

      # Default `:resolve` set below.
      # 
      # _@return_ — The method to call on instances of this object to resolve the field
      sig { params(new_method: T.untyped).returns(Symbol) }
      def self.resolve_method(new_method = nil); end

      # Additional info injected into {#resolve}
      # 
      # _@see_ `{GraphQL::Schema::Field#extras}`
      sig { params(new_extras: T.untyped).returns(T.untyped) }
      def self.extras(new_extras = nil); end

      # Specifies whether or not the field is nullable. Defaults to `true`
      # TODO unify with {#type}
      # 
      # _@param_ `allow_null` — Whether or not the response can be null
      sig { params(allow_null: T.nilable(T::Boolean)).returns(T.untyped) }
      def self.null(allow_null = nil); end

      # Call this method to get the return type of the field,
      # or use it as a configuration method to assign a return type
      # instead of generating one.
      # TODO unify with {#null}
      # 
      # _@param_ `new_type` — If a type definition class is provided, it will be used as the return type of the field
      # 
      # _@param_ `null` — Whether or not the field may return `nil`
      # 
      # _@return_ — The type which this field returns.
      sig { params(new_type: T.nilable(Class), null: T.nilable(T::Boolean)).returns(Class) }
      def self.type(new_type = nil, null: nil); end

      # Specifies the complexity of the field. Defaults to `1`
      sig { params(new_complexity: T.untyped).returns(T.any(Integer, Proc)) }
      def self.complexity(new_complexity = nil); end

      sig { returns(T.untyped) }
      def self.field_options; end

      # A non-normalized type configuration, without `null` applied
      sig { returns(T.untyped) }
      def self.type_expr; end

      # Add an argument to this field's signature, but
      # also add some preparation hook methods which will be used for this argument
      # 
      # _@see_ `{GraphQL::Schema::Argument#initialize}` — for the signature
      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(T.untyped) }
      def self.argument(*args, **kwargs, &block); end

      sig { returns(T.untyped) }
      def self.arguments_loads_as_type; end

      sig { returns(T.untyped) }
      def self.own_arguments_loads_as_type; end

      # _@return_ — A description of this member's place in the GraphQL schema
      sig { returns(String) }
      def self.path; end

      # Register this argument with the class.
      # 
      # _@param_ `arg_defn` — 
      sig { params(arg_defn: GraphQL::Schema::Argument).returns(GraphQL::Schema::Argument) }
      def self.add_argument(arg_defn); end

      # _@return_ — Hash<String => GraphQL::Schema::Argument] Arguments defined on this thing, keyed by name. Includes inherited definitions
      sig { returns(T.untyped) }
      def self.arguments; end

      # _@param_ `new_arg_class` — A class to use for building argument definitions
      sig { params(new_arg_class: T.nilable(Class)).returns(T.untyped) }
      def self.argument_class(new_arg_class = nil); end

      sig { returns(T.untyped) }
      def self.own_arguments; end

      # Call this with a new name to override the default name for this schema member; OR
      # call it without an argument to get the name of this schema member
      # 
      # The default name is implemented in default_graphql_name
      # 
      # _@param_ `new_name` — 
      sig { params(new_name: T.nilable(String)).returns(String) }
      def self.graphql_name(new_name = nil); end

      # Just a convenience method to point out that people should use graphql_name instead
      sig { params(new_name: T.untyped).returns(T.untyped) }
      def self.name(new_name = nil); end

      # Call this method to provide a new description; OR
      # call it without an argument to get the description
      # 
      # _@param_ `new_description` — 
      sig { params(new_description: T.nilable(String)).returns(String) }
      def self.description(new_description = nil); end

      # _@return_ — If true, this object is part of the introspection system
      sig { params(new_introspection: T.untyped).returns(T::Boolean) }
      def self.introspection(new_introspection = nil); end

      sig { returns(T::Boolean) }
      def self.introspection?; end

      # The mutation this type was derived from, if it was derived from a mutation
      sig { params(mutation_class: T.untyped).returns(Class) }
      def self.mutation(mutation_class = nil); end

      # _@return_ — Convert this type to a legacy-style object.
      sig { returns(GraphQL::BaseType) }
      def self.to_graphql; end

      sig { returns(T.untyped) }
      def self.overridden_graphql_name; end

      # Creates the default name for a schema member.
      # The default name is the Ruby constant name,
      # without any namespaces and with any `-Type` suffix removed
      sig { returns(T.untyped) }
      def self.default_graphql_name; end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def self.visible?(context); end

      sig { params(context: T.untyped).returns(T::Boolean) }
      def self.accessible?(context); end

      sig { params(object: T.untyped, context: T.untyped).returns(T::Boolean) }
      def self.authorized?(object, context); end

      sig { params(method_name: T.untyped, default_value: T.untyped).returns(T.untyped) }
      def self.find_inherited_value(method_name, default_value = nil); end

      # _@return_ — A description of this member's place in the GraphQL schema
      sig { returns(String) }
      def path; end

      # Adds `field(...)` helper to resolvers so that they can
      # generate payload types.
      # 
      # Or, an already-defined one can be attached with `payload_type(...)`.
      module HasPayloadType
        # Call this method to get the derived return type of the mutation,
        # or use it as a configuration method to assign a return type
        # instead of generating one.
        # 
        # _@param_ `new_payload_type` — If a type definition class is provided, it will be used as the return type of the mutation field
        # 
        # _@return_ — The object type which this mutation returns.
        sig { params(new_payload_type: T.nilable(Class)).returns(Class) }
        def payload_type(new_payload_type = nil); end

        sig { params(new_class: T.untyped).returns(T.untyped) }
        def field_class(new_class = nil); end

        # An object class to use for deriving return types
        # 
        # _@param_ `new_class` — Defaults to {GraphQL::Schema::Object}
        sig { params(new_class: T.nilable(Class)).returns(Class) }
        def object_class(new_class = nil); end

        # Build a subclass of {.object_class} based on `self`.
        # This value will be cached as `{.payload_type}`.
        # Override this hook to customize return type generation.
        sig { returns(T.untyped) }
        def generate_payload_type; end
      end
    end

    # Subclasses of this can influence how {GraphQL::Execution::Interpreter} runs queries.
    # 
    # - {.include?}: if it returns `false`, the field or fragment will be skipped altogether, as if it were absent
    # - {.resolve}: Wraps field resolution (so it should call `yield` to continue)
    class Directive < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::HasArguments
      LOCATIONS = T.let([
  QUERY =                  :QUERY,
  MUTATION =               :MUTATION,
  SUBSCRIPTION =           :SUBSCRIPTION,
  FIELD =                  :FIELD,
  FRAGMENT_DEFINITION =    :FRAGMENT_DEFINITION,
  FRAGMENT_SPREAD =        :FRAGMENT_SPREAD,
  INLINE_FRAGMENT =        :INLINE_FRAGMENT,
  SCHEMA =                 :SCHEMA,
  SCALAR =                 :SCALAR,
  OBJECT =                 :OBJECT,
  FIELD_DEFINITION =       :FIELD_DEFINITION,
  ARGUMENT_DEFINITION =    :ARGUMENT_DEFINITION,
  INTERFACE =              :INTERFACE,
  UNION =                  :UNION,
  ENUM =                   :ENUM,
  ENUM_VALUE =             :ENUM_VALUE,
  INPUT_OBJECT =           :INPUT_OBJECT,
  INPUT_FIELD_DEFINITION = :INPUT_FIELD_DEFINITION,
], T.untyped)
      DEFAULT_DEPRECATION_REASON = T.let('No longer supported', T.untyped)
      LOCATION_DESCRIPTIONS = T.let({
  QUERY:                    'Location adjacent to a query operation.',
  MUTATION:                 'Location adjacent to a mutation operation.',
  SUBSCRIPTION:             'Location adjacent to a subscription operation.',
  FIELD:                    'Location adjacent to a field.',
  FRAGMENT_DEFINITION:      'Location adjacent to a fragment definition.',
  FRAGMENT_SPREAD:          'Location adjacent to a fragment spread.',
  INLINE_FRAGMENT:          'Location adjacent to an inline fragment.',
  SCHEMA:                   'Location adjacent to a schema definition.',
  SCALAR:                   'Location adjacent to a scalar definition.',
  OBJECT:                   'Location adjacent to an object type definition.',
  FIELD_DEFINITION:         'Location adjacent to a field definition.',
  ARGUMENT_DEFINITION:      'Location adjacent to an argument definition.',
  INTERFACE:                'Location adjacent to an interface definition.',
  UNION:                    'Location adjacent to a union definition.',
  ENUM:                     'Location adjacent to an enum definition.',
  ENUM_VALUE:               'Location adjacent to an enum value definition.',
  INPUT_OBJECT:             'Location adjacent to an input object type definition.',
  INPUT_FIELD_DEFINITION:   'Location adjacent to an input object field definition.',
}, T.untyped)
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def self.default_graphql_name; end

      sig { params(new_locations: T.untyped).returns(T.untyped) }
      def self.locations(*new_locations); end

      sig { params(new_default_directive: T.untyped).returns(T.untyped) }
      def self.default_directive(new_default_directive = nil); end

      sig { returns(T::Boolean) }
      def self.default_directive?; end

      sig { returns(T.untyped) }
      def self.to_graphql; end

      # If false, this part of the query won't be evaluated
      sig { params(_object: T.untyped, _arguments: T.untyped, _context: T.untyped).returns(T::Boolean) }
      def self.include?(_object, _arguments, _context); end

      # Continuing is passed as a block; `yield` to continue
      sig { params(object: T.untyped, arguments: T.untyped, context: T.untyped).returns(T.untyped) }
      def self.resolve(object, arguments, context); end

      # _@return_ — An instance of {arguments_class}, created from `*args`
      # 
      # _@see_ `{GraphQL::Schema::Argument#initialize}` — for parameters
      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(GraphQL::Schema::Argument) }
      def self.argument(*args, **kwargs, &block); end

      # Register this argument with the class.
      # 
      # _@param_ `arg_defn` — 
      sig { params(arg_defn: GraphQL::Schema::Argument).returns(GraphQL::Schema::Argument) }
      def self.add_argument(arg_defn); end

      # _@return_ — Hash<String => GraphQL::Schema::Argument] Arguments defined on this thing, keyed by name. Includes inherited definitions
      sig { returns(T.untyped) }
      def self.arguments; end

      # _@param_ `new_arg_class` — A class to use for building argument definitions
      sig { params(new_arg_class: T.nilable(Class)).returns(T.untyped) }
      def self.argument_class(new_arg_class = nil); end

      sig { returns(T.untyped) }
      def self.own_arguments; end

      class Skip < GraphQL::Schema::Directive
        LOCATIONS = T.let([
  QUERY =                  :QUERY,
  MUTATION =               :MUTATION,
  SUBSCRIPTION =           :SUBSCRIPTION,
  FIELD =                  :FIELD,
  FRAGMENT_DEFINITION =    :FRAGMENT_DEFINITION,
  FRAGMENT_SPREAD =        :FRAGMENT_SPREAD,
  INLINE_FRAGMENT =        :INLINE_FRAGMENT,
  SCHEMA =                 :SCHEMA,
  SCALAR =                 :SCALAR,
  OBJECT =                 :OBJECT,
  FIELD_DEFINITION =       :FIELD_DEFINITION,
  ARGUMENT_DEFINITION =    :ARGUMENT_DEFINITION,
  INTERFACE =              :INTERFACE,
  UNION =                  :UNION,
  ENUM =                   :ENUM,
  ENUM_VALUE =             :ENUM_VALUE,
  INPUT_OBJECT =           :INPUT_OBJECT,
  INPUT_FIELD_DEFINITION = :INPUT_FIELD_DEFINITION,
], T.untyped)
        DEFAULT_DEPRECATION_REASON = T.let('No longer supported', T.untyped)
        LOCATION_DESCRIPTIONS = T.let({
  QUERY:                    'Location adjacent to a query operation.',
  MUTATION:                 'Location adjacent to a mutation operation.',
  SUBSCRIPTION:             'Location adjacent to a subscription operation.',
  FIELD:                    'Location adjacent to a field.',
  FRAGMENT_DEFINITION:      'Location adjacent to a fragment definition.',
  FRAGMENT_SPREAD:          'Location adjacent to a fragment spread.',
  INLINE_FRAGMENT:          'Location adjacent to an inline fragment.',
  SCHEMA:                   'Location adjacent to a schema definition.',
  SCALAR:                   'Location adjacent to a scalar definition.',
  OBJECT:                   'Location adjacent to an object type definition.',
  FIELD_DEFINITION:         'Location adjacent to a field definition.',
  ARGUMENT_DEFINITION:      'Location adjacent to an argument definition.',
  INTERFACE:                'Location adjacent to an interface definition.',
  UNION:                    'Location adjacent to a union definition.',
  ENUM:                     'Location adjacent to an enum definition.',
  ENUM_VALUE:               'Location adjacent to an enum value definition.',
  INPUT_OBJECT:             'Location adjacent to an input object type definition.',
  INPUT_FIELD_DEFINITION:   'Location adjacent to an input object field definition.',
}, T.untyped)
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T::Boolean) }
        def self.include?(obj, args, ctx); end
      end

      # An example directive to show how you might interact with the runtime.
      # 
      # This directive might be used along with a server-side feature flag system like Flipper.
      # 
      # With that system, you could use this directive to exclude parts of a query
      # if the current viewer doesn't have certain flags enabled.
      # (So, this flag would be for internal clients, like your iOS app, not third-party API clients.)
      # 
      # To use it, you have to implement `.enabled?`, for example:
      # 
      # @example Implementing the Feature directive
      #   # app/graphql/directives/feature.rb
      #   class Directives::Feature < GraphQL::Schema::Directive::Feature
      #     def self.enabled?(flag_name, _obj, context)
      #       # Translate some GraphQL data for Ruby:
      #       flag_key = flag_name.underscore
      #       current_user = context[:viewer]
      #       # Check the feature flag however your app does it:
      #       MyFeatureFlags.enabled?(current_user, flag_key)
      #     end
      #   end
      # 
      # @example Flagging a part of the query
      #   viewer {
      #     # This field only runs if `.enabled?("recommendationEngine", obj, context)`
      #     # returns true. Otherwise, it's treated as if it didn't exist.
      #     recommendations @feature(flag: "recommendationEngine") {
      #       name
      #       rating
      #     }
      #   }
      class Feature < GraphQL::Schema::Directive
        LOCATIONS = T.let([
  QUERY =                  :QUERY,
  MUTATION =               :MUTATION,
  SUBSCRIPTION =           :SUBSCRIPTION,
  FIELD =                  :FIELD,
  FRAGMENT_DEFINITION =    :FRAGMENT_DEFINITION,
  FRAGMENT_SPREAD =        :FRAGMENT_SPREAD,
  INLINE_FRAGMENT =        :INLINE_FRAGMENT,
  SCHEMA =                 :SCHEMA,
  SCALAR =                 :SCALAR,
  OBJECT =                 :OBJECT,
  FIELD_DEFINITION =       :FIELD_DEFINITION,
  ARGUMENT_DEFINITION =    :ARGUMENT_DEFINITION,
  INTERFACE =              :INTERFACE,
  UNION =                  :UNION,
  ENUM =                   :ENUM,
  ENUM_VALUE =             :ENUM_VALUE,
  INPUT_OBJECT =           :INPUT_OBJECT,
  INPUT_FIELD_DEFINITION = :INPUT_FIELD_DEFINITION,
], T.untyped)
        DEFAULT_DEPRECATION_REASON = T.let('No longer supported', T.untyped)
        LOCATION_DESCRIPTIONS = T.let({
  QUERY:                    'Location adjacent to a query operation.',
  MUTATION:                 'Location adjacent to a mutation operation.',
  SUBSCRIPTION:             'Location adjacent to a subscription operation.',
  FIELD:                    'Location adjacent to a field.',
  FRAGMENT_DEFINITION:      'Location adjacent to a fragment definition.',
  FRAGMENT_SPREAD:          'Location adjacent to a fragment spread.',
  INLINE_FRAGMENT:          'Location adjacent to an inline fragment.',
  SCHEMA:                   'Location adjacent to a schema definition.',
  SCALAR:                   'Location adjacent to a scalar definition.',
  OBJECT:                   'Location adjacent to an object type definition.',
  FIELD_DEFINITION:         'Location adjacent to a field definition.',
  ARGUMENT_DEFINITION:      'Location adjacent to an argument definition.',
  INTERFACE:                'Location adjacent to an interface definition.',
  UNION:                    'Location adjacent to a union definition.',
  ENUM:                     'Location adjacent to an enum definition.',
  ENUM_VALUE:               'Location adjacent to an enum value definition.',
  INPUT_OBJECT:             'Location adjacent to an input object type definition.',
  INPUT_FIELD_DEFINITION:   'Location adjacent to an input object field definition.',
}, T.untyped)
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        # Implement the Directive API
        sig { params(object: T.untyped, arguments: T.untyped, context: T.untyped).returns(T::Boolean) }
        def self.include?(object, arguments, context); end

        # Override this method in your app's subclass of this directive.
        # 
        # _@param_ `flag_name` — The client-provided string of a feature to check
        # 
        # _@param_ `object` — The currently-evaluated GraphQL object instance
        # 
        # _@param_ `context` — 
        # 
        # _@return_ — If truthy, execution will continue
        sig { params(flag_name: String, object: T.untyped, context: GraphQL::Query::Context).returns(T::Boolean) }
        def self.enabled?(flag_name, object, context); end
      end

      class Include < GraphQL::Schema::Directive
        LOCATIONS = T.let([
  QUERY =                  :QUERY,
  MUTATION =               :MUTATION,
  SUBSCRIPTION =           :SUBSCRIPTION,
  FIELD =                  :FIELD,
  FRAGMENT_DEFINITION =    :FRAGMENT_DEFINITION,
  FRAGMENT_SPREAD =        :FRAGMENT_SPREAD,
  INLINE_FRAGMENT =        :INLINE_FRAGMENT,
  SCHEMA =                 :SCHEMA,
  SCALAR =                 :SCALAR,
  OBJECT =                 :OBJECT,
  FIELD_DEFINITION =       :FIELD_DEFINITION,
  ARGUMENT_DEFINITION =    :ARGUMENT_DEFINITION,
  INTERFACE =              :INTERFACE,
  UNION =                  :UNION,
  ENUM =                   :ENUM,
  ENUM_VALUE =             :ENUM_VALUE,
  INPUT_OBJECT =           :INPUT_OBJECT,
  INPUT_FIELD_DEFINITION = :INPUT_FIELD_DEFINITION,
], T.untyped)
        DEFAULT_DEPRECATION_REASON = T.let('No longer supported', T.untyped)
        LOCATION_DESCRIPTIONS = T.let({
  QUERY:                    'Location adjacent to a query operation.',
  MUTATION:                 'Location adjacent to a mutation operation.',
  SUBSCRIPTION:             'Location adjacent to a subscription operation.',
  FIELD:                    'Location adjacent to a field.',
  FRAGMENT_DEFINITION:      'Location adjacent to a fragment definition.',
  FRAGMENT_SPREAD:          'Location adjacent to a fragment spread.',
  INLINE_FRAGMENT:          'Location adjacent to an inline fragment.',
  SCHEMA:                   'Location adjacent to a schema definition.',
  SCALAR:                   'Location adjacent to a scalar definition.',
  OBJECT:                   'Location adjacent to an object type definition.',
  FIELD_DEFINITION:         'Location adjacent to a field definition.',
  ARGUMENT_DEFINITION:      'Location adjacent to an argument definition.',
  INTERFACE:                'Location adjacent to an interface definition.',
  UNION:                    'Location adjacent to a union definition.',
  ENUM:                     'Location adjacent to an enum definition.',
  ENUM_VALUE:               'Location adjacent to an enum value definition.',
  INPUT_OBJECT:             'Location adjacent to an input object type definition.',
  INPUT_FIELD_DEFINITION:   'Location adjacent to an input object field definition.',
}, T.untyped)
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T::Boolean) }
        def self.include?(obj, args, ctx); end
      end

      # An example directive to show how you might interact with the runtime.
      # 
      # This directive takes the return value of the tagged part of the query,
      # and if the named transform is whitelisted and applies to the return value,
      # it's applied by calling a method with that name.
      # 
      # @example Installing the directive
      #   class MySchema < GraphQL::Schema
      #     directive(GraphQL::Schema::Directive::Transform)
      #   end
      # 
      # @example Transforming strings
      #   viewer {
      #     username @transform(by: "upcase")
      #   }
      class Transform < GraphQL::Schema::Directive
        TRANSFORMS = T.let([
  "upcase",
  "downcase",
  # ??
], T.untyped)
        LOCATIONS = T.let([
  QUERY =                  :QUERY,
  MUTATION =               :MUTATION,
  SUBSCRIPTION =           :SUBSCRIPTION,
  FIELD =                  :FIELD,
  FRAGMENT_DEFINITION =    :FRAGMENT_DEFINITION,
  FRAGMENT_SPREAD =        :FRAGMENT_SPREAD,
  INLINE_FRAGMENT =        :INLINE_FRAGMENT,
  SCHEMA =                 :SCHEMA,
  SCALAR =                 :SCALAR,
  OBJECT =                 :OBJECT,
  FIELD_DEFINITION =       :FIELD_DEFINITION,
  ARGUMENT_DEFINITION =    :ARGUMENT_DEFINITION,
  INTERFACE =              :INTERFACE,
  UNION =                  :UNION,
  ENUM =                   :ENUM,
  ENUM_VALUE =             :ENUM_VALUE,
  INPUT_OBJECT =           :INPUT_OBJECT,
  INPUT_FIELD_DEFINITION = :INPUT_FIELD_DEFINITION,
], T.untyped)
        DEFAULT_DEPRECATION_REASON = T.let('No longer supported', T.untyped)
        LOCATION_DESCRIPTIONS = T.let({
  QUERY:                    'Location adjacent to a query operation.',
  MUTATION:                 'Location adjacent to a mutation operation.',
  SUBSCRIPTION:             'Location adjacent to a subscription operation.',
  FIELD:                    'Location adjacent to a field.',
  FRAGMENT_DEFINITION:      'Location adjacent to a fragment definition.',
  FRAGMENT_SPREAD:          'Location adjacent to a fragment spread.',
  INLINE_FRAGMENT:          'Location adjacent to an inline fragment.',
  SCHEMA:                   'Location adjacent to a schema definition.',
  SCALAR:                   'Location adjacent to a scalar definition.',
  OBJECT:                   'Location adjacent to an object type definition.',
  FIELD_DEFINITION:         'Location adjacent to a field definition.',
  ARGUMENT_DEFINITION:      'Location adjacent to an argument definition.',
  INTERFACE:                'Location adjacent to an interface definition.',
  UNION:                    'Location adjacent to a union definition.',
  ENUM:                     'Location adjacent to an enum definition.',
  ENUM_VALUE:               'Location adjacent to an enum value definition.',
  INPUT_OBJECT:             'Location adjacent to an input object type definition.',
  INPUT_FIELD_DEFINITION:   'Location adjacent to an input object field definition.',
}, T.untyped)
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        # Implement the Directive API
        sig { params(object: T.untyped, arguments: T.untyped, context: T.untyped).returns(T.untyped) }
        def self.resolve(object, arguments, context); end
      end
    end

    module Interface
      include GraphQL::Schema::Member::GraphQLTypeNames
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend GraphQL::Schema::Interface::DefinitionMethods
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def unwrap; end

      # Methods defined in this block will be:
      # - Added as class methods to this interface
      # - Added as class methods to all child interfaces
      sig { params(block: T.untyped).returns(T.untyped) }
      def self.definition_methods(&block); end

      # The interface is visible if any of its possible types are visible
      sig { params(context: T.untyped).returns(T::Boolean) }
      def self.visible?(context); end

      # The interface is accessible if any of its possible types are accessible
      sig { params(context: T.untyped).returns(T::Boolean) }
      def self.accessible?(context); end

      # Here's the tricky part. Make sure behavior keeps making its way down the inheritance chain.
      sig { params(child_class: T.untyped).returns(T.untyped) }
      def self.included(child_class); end

      sig { params(types: T.untyped).returns(T.untyped) }
      def self.orphan_types(*types); end

      sig { returns(T.untyped) }
      def self.to_graphql; end

      sig { returns(T.untyped) }
      def self.kind; end

      sig { returns(T.untyped) }
      def self.own_interfaces; end

      sig { returns(T.untyped) }
      def self.interfaces; end

      # If this schema was parsed from a `.graphql` file (or other SDL),
      # this is the AST node that defined this part of the schema.
      sig { params(new_ast_node: T.untyped).returns(T.untyped) }
      def self.ast_node(new_ast_node = nil); end

      # This is called when a field has `scope: true`.
      # The field's return type class receives this call.
      # 
      # By default, it's a no-op. Override it to scope your objects.
      # 
      # _@param_ `items` — Some list-like object (eg, Array, ActiveRecord::Relation)
      # 
      # _@param_ `context` — 
      # 
      # _@return_ — Another list-like object, scoped to the current context
      sig { params(items: T.untyped, context: GraphQL::Query::Context).returns(T.untyped) }
      def self.scope_items(items, context); end

      sig { params(new_edge_type_class: T.untyped).returns(T.untyped) }
      def self.edge_type_class(new_edge_type_class = nil); end

      sig { params(new_connection_type_class: T.untyped).returns(T.untyped) }
      def self.connection_type_class(new_connection_type_class = nil); end

      sig { returns(T.untyped) }
      def self.edge_type; end

      sig { returns(T.untyped) }
      def self.connection_type; end

      # _@return_ — A description of this member's place in the GraphQL schema
      sig { returns(String) }
      def self.path; end

      # Add a field to this object or interface with the given definition
      # 
      # _@see_ `{GraphQL::Schema::Field#initialize}` — for method signature
      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(GraphQL::Schema::Field) }
      def self.field(*args, **kwargs, &block); end

      # _@return_ — Fields on this object, keyed by name, including inherited fields
      sig { returns(T::Hash[String, GraphQL::Schema::Field]) }
      def self.fields; end

      sig { params(field_name: T.untyped).returns(T.untyped) }
      def self.get_field(field_name); end

      # Register this field with the class, overriding a previous one if needed.
      # 
      # _@param_ `field_defn` — 
      sig { params(field_defn: GraphQL::Schema::Field).void }
      def self.add_field(field_defn); end

      # _@return_ — The class to initialize when adding fields to this kind of schema member
      sig { params(new_field_class: T.untyped).returns(Class) }
      def self.field_class(new_field_class = nil); end

      sig { params(field_name: T.untyped).returns(T.untyped) }
      def self.global_id_field(field_name); end

      # _@return_ — Fields defined on this class _specifically_, not parent classes
      sig { returns(T::Array[GraphQL::Schema::Field]) }
      def self.own_fields; end

      # _@return_ — Make a non-null-type representation of this type
      sig { returns(Schema::NonNull) }
      def self.to_non_null_type; end

      # _@return_ — Make a list-type representation of this type
      sig { returns(Schema::List) }
      def self.to_list_type; end

      # _@return_ — true if this is a non-nullable type. A nullable list of non-nullables is considered nullable.
      sig { returns(T::Boolean) }
      def self.non_null?; end

      # _@return_ — true if this is a list type. A non-nullable list is considered a list.
      sig { returns(T::Boolean) }
      def self.list?; end

      sig { returns(T.untyped) }
      def self.to_type_signature; end

      # Call this with a new name to override the default name for this schema member; OR
      # call it without an argument to get the name of this schema member
      # 
      # The default name is implemented in default_graphql_name
      # 
      # _@param_ `new_name` — 
      sig { params(new_name: T.nilable(String)).returns(String) }
      def self.graphql_name(new_name = nil); end

      # Just a convenience method to point out that people should use graphql_name instead
      sig { params(new_name: T.untyped).returns(T.untyped) }
      def self.name(new_name = nil); end

      # Call this method to provide a new description; OR
      # call it without an argument to get the description
      # 
      # _@param_ `new_description` — 
      sig { params(new_description: T.nilable(String)).returns(String) }
      def self.description(new_description = nil); end

      # _@return_ — If true, this object is part of the introspection system
      sig { params(new_introspection: T.untyped).returns(T::Boolean) }
      def self.introspection(new_introspection = nil); end

      sig { returns(T::Boolean) }
      def self.introspection?; end

      # The mutation this type was derived from, if it was derived from a mutation
      sig { params(mutation_class: T.untyped).returns(Class) }
      def self.mutation(mutation_class = nil); end

      sig { returns(T.untyped) }
      def self.overridden_graphql_name; end

      # Creates the default name for a schema member.
      # The default name is the Ruby constant name,
      # without any namespaces and with any `-Type` suffix removed
      sig { returns(T.untyped) }
      def self.default_graphql_name; end

      sig { params(object: T.untyped, context: T.untyped).returns(T::Boolean) }
      def self.authorized?(object, context); end

      sig { params(method_name: T.untyped, default_value: T.untyped).returns(T.untyped) }
      def self.find_inherited_value(method_name, default_value = nil); end

      # Define a custom connection type for this object type
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
      def self.define_connection(**kwargs, &block); end

      # Define a custom edge type for this object type
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
      def self.define_edge(**kwargs, &block); end

      # A cached result of {.to_graphql}.
      # It's cached here so that user-overridden {.to_graphql} implementations
      # are also cached
      sig { returns(T.untyped) }
      def self.graphql_definition; end

      # This is for a common interface with .define-based types
      sig { returns(T.untyped) }
      def self.type_class; end

      # Wipe out the cached graphql_definition so that `.to_graphql` will be called again.
      sig { params(original: T.untyped).returns(T.untyped) }
      def self.initialize_copy(original); end

      module DefinitionMethods
        include GraphQL::Schema::Member::CachedGraphQLDefinition
        include GraphQL::Relay::TypeExtensions
        include GraphQL::Schema::Member::BaseDSLMethods
        include GraphQL::Schema::Member::TypeSystemHelpers
        include GraphQL::Schema::Member::HasFields
        include GraphQL::Schema::Member::HasPath
        include GraphQL::Schema::Member::RelayShortcuts
        include GraphQL::Schema::Member::Scoped
        include GraphQL::Schema::Member::HasAstNode
        CONFLICT_FIELD_NAMES = T.let(Set.new([
  # GraphQL-Ruby conflicts
  :context, :object,
  # Ruby built-ins conflicts
  :method, :class
]), T.untyped)

        # Methods defined in this block will be:
        # - Added as class methods to this interface
        # - Added as class methods to all child interfaces
        sig { params(block: T.untyped).returns(T.untyped) }
        def definition_methods(&block); end

        # The interface is visible if any of its possible types are visible
        sig { params(context: T.untyped).returns(T::Boolean) }
        def visible?(context); end

        # The interface is accessible if any of its possible types are accessible
        sig { params(context: T.untyped).returns(T::Boolean) }
        def accessible?(context); end

        # Here's the tricky part. Make sure behavior keeps making its way down the inheritance chain.
        sig { params(child_class: T.untyped).returns(T.untyped) }
        def included(child_class); end

        sig { params(types: T.untyped).returns(T.untyped) }
        def orphan_types(*types); end

        sig { returns(T.untyped) }
        def to_graphql; end

        sig { returns(T.untyped) }
        def kind; end

        sig { returns(T.untyped) }
        def own_interfaces; end

        sig { returns(T.untyped) }
        def interfaces; end

        # If this schema was parsed from a `.graphql` file (or other SDL),
        # this is the AST node that defined this part of the schema.
        sig { params(new_ast_node: T.untyped).returns(T.untyped) }
        def ast_node(new_ast_node = nil); end

        # This is called when a field has `scope: true`.
        # The field's return type class receives this call.
        # 
        # By default, it's a no-op. Override it to scope your objects.
        # 
        # _@param_ `items` — Some list-like object (eg, Array, ActiveRecord::Relation)
        # 
        # _@param_ `context` — 
        # 
        # _@return_ — Another list-like object, scoped to the current context
        sig { params(items: T.untyped, context: GraphQL::Query::Context).returns(T.untyped) }
        def scope_items(items, context); end

        sig { params(new_edge_type_class: T.untyped).returns(T.untyped) }
        def edge_type_class(new_edge_type_class = nil); end

        sig { params(new_connection_type_class: T.untyped).returns(T.untyped) }
        def connection_type_class(new_connection_type_class = nil); end

        sig { returns(T.untyped) }
        def edge_type; end

        sig { returns(T.untyped) }
        def connection_type; end

        # _@return_ — A description of this member's place in the GraphQL schema
        sig { returns(String) }
        def path; end

        # Add a field to this object or interface with the given definition
        # 
        # _@see_ `{GraphQL::Schema::Field#initialize}` — for method signature
        sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(GraphQL::Schema::Field) }
        def field(*args, **kwargs, &block); end

        # _@return_ — Fields on this object, keyed by name, including inherited fields
        sig { returns(T::Hash[String, GraphQL::Schema::Field]) }
        def fields; end

        sig { params(field_name: T.untyped).returns(T.untyped) }
        def get_field(field_name); end

        # Register this field with the class, overriding a previous one if needed.
        # 
        # _@param_ `field_defn` — 
        sig { params(field_defn: GraphQL::Schema::Field).void }
        def add_field(field_defn); end

        # _@return_ — The class to initialize when adding fields to this kind of schema member
        sig { params(new_field_class: T.untyped).returns(Class) }
        def field_class(new_field_class = nil); end

        sig { params(field_name: T.untyped).returns(T.untyped) }
        def global_id_field(field_name); end

        # _@return_ — Fields defined on this class _specifically_, not parent classes
        sig { returns(T::Array[GraphQL::Schema::Field]) }
        def own_fields; end

        # _@return_ — Make a non-null-type representation of this type
        sig { returns(Schema::NonNull) }
        def to_non_null_type; end

        # _@return_ — Make a list-type representation of this type
        sig { returns(Schema::List) }
        def to_list_type; end

        # _@return_ — true if this is a non-nullable type. A nullable list of non-nullables is considered nullable.
        sig { returns(T::Boolean) }
        def non_null?; end

        # _@return_ — true if this is a list type. A non-nullable list is considered a list.
        sig { returns(T::Boolean) }
        def list?; end

        sig { returns(T.untyped) }
        def to_type_signature; end

        # Call this with a new name to override the default name for this schema member; OR
        # call it without an argument to get the name of this schema member
        # 
        # The default name is implemented in default_graphql_name
        # 
        # _@param_ `new_name` — 
        sig { params(new_name: T.nilable(String)).returns(String) }
        def graphql_name(new_name = nil); end

        # Just a convenience method to point out that people should use graphql_name instead
        sig { params(new_name: T.untyped).returns(T.untyped) }
        def name(new_name = nil); end

        # Call this method to provide a new description; OR
        # call it without an argument to get the description
        # 
        # _@param_ `new_description` — 
        sig { params(new_description: T.nilable(String)).returns(String) }
        def description(new_description = nil); end

        # _@return_ — If true, this object is part of the introspection system
        sig { params(new_introspection: T.untyped).returns(T::Boolean) }
        def introspection(new_introspection = nil); end

        sig { returns(T::Boolean) }
        def introspection?; end

        # The mutation this type was derived from, if it was derived from a mutation
        sig { params(mutation_class: T.untyped).returns(Class) }
        def mutation(mutation_class = nil); end

        sig { returns(T.untyped) }
        def overridden_graphql_name; end

        # Creates the default name for a schema member.
        # The default name is the Ruby constant name,
        # without any namespaces and with any `-Type` suffix removed
        sig { returns(T.untyped) }
        def default_graphql_name; end

        sig { params(object: T.untyped, context: T.untyped).returns(T::Boolean) }
        def authorized?(object, context); end

        sig { params(method_name: T.untyped, default_value: T.untyped).returns(T.untyped) }
        def find_inherited_value(method_name, default_value = nil); end

        # Define a custom connection type for this object type
        sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
        def define_connection(**kwargs, &block); end

        # Define a custom edge type for this object type
        sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
        def define_edge(**kwargs, &block); end

        # A cached result of {.to_graphql}.
        # It's cached here so that user-overridden {.to_graphql} implementations
        # are also cached
        sig { returns(T.untyped) }
        def graphql_definition; end

        # This is for a common interface with .define-based types
        sig { returns(T.untyped) }
        def type_class; end

        # Wipe out the cached graphql_definition so that `.to_graphql` will be called again.
        sig { params(original: T.untyped).returns(T.untyped) }
        def initialize_copy(original); end
      end
    end

    # @api private
    module NullMask
      sig { params(member: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.call(member, ctx); end
    end

    # Visit the members of this schema and build up artifacts for runtime.
    # @api private
    class Traversal
      # _@return_ — Hash<String => GraphQL::BaseType]
      sig { returns(T.untyped) }
      def type_map; end

      sig { returns(T::Hash[String, T::Hash[String, GraphQL::Field]]) }
      def instrumented_field_map; end

      # _@return_ — Hash<String => Array<GraphQL::Field || GraphQL::Argument || GraphQL::Directive>]
      sig { returns(T.untyped) }
      def type_reference_map; end

      # _@return_ — Hash<String => Array<GraphQL::BaseType>]
      sig { returns(T.untyped) }
      def union_memberships; end

      # _@param_ `schema` — 
      sig { params(schema: GraphQL::Schema, introspection: T.untyped).returns(Traversal) }
      def initialize(schema, introspection: true); end

      # A brute-force appraoch to late binding.
      # Just keep trying the whole list, hoping that they
      # eventually all resolve.
      # This could be replaced with proper dependency tracking.
      sig { returns(T.untyped) }
      def resolve_late_bound_fields; end

      # The late-bound type may be wrapped with list or non-null types.
      # Apply the same wrapping to the resolve type and
      # return the maybe-wrapped type
      sig { params(late_bound_type: T.untyped, resolved_inner_type: T.untyped).returns(T.untyped) }
      def rewrap_resolved_type(late_bound_type, resolved_inner_type); end

      sig { params(schema: T.untyped, member: T.untyped, context_description: T.untyped).returns(T.untyped) }
      def visit(schema, member, context_description); end

      sig { params(schema: T.untyped, type_defn: T.untyped).returns(T.untyped) }
      def visit_fields(schema, type_defn); end

      sig do
        params(
          schema: T.untyped,
          type_defn: T.untyped,
          field_defn: T.untyped,
          dynamic_field: T.untyped
        ).returns(T.untyped)
      end
      def visit_field_on_type(schema, type_defn, field_defn, dynamic_field: false); end

      sig { params(member: T.untyped, context_description: T.untyped).returns(T.untyped) }
      def validate_type(member, context_description); end
    end

    # A possible value for an {Enum}.
    # 
    # You can extend this class to customize enum values in your schema.
    # 
    # @example custom enum value class
    #   # define a custom class:
    #   class CustomEnumValue < GraphQL::Schema::EnumValue
    #     def initialize(*args)
    #       # arguments to `value(...)` in Enum classes are passed here
    #       super
    #     end
    # 
    #     def to_graphql
    #       enum_value = super
    #       # customize the derived GraphQL::EnumValue here
    #       enum_value
    #     end
    #   end
    # 
    #   class BaseEnum < GraphQL::Schema::Enum
    #     # use it for these enums:
    #     enum_value_class CustomEnumValue
    #   end
    class EnumValue < GraphQL::Schema::Member
      include GraphQL::Schema::Member::AcceptsDefinition
      include GraphQL::Schema::Member::HasPath
      include GraphQL::Schema::Member::HasAstNode
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # Returns the value of attribute graphql_name
      sig { returns(T.untyped) }
      def graphql_name; end

      # _@return_ — The enum type that owns this value
      sig { returns(Class) }
      def owner; end

      # _@return_ — Explains why this value was deprecated (if present, this will be marked deprecated in introspection)
      sig { returns(String) }
      def deprecation_reason; end

      # _@return_ — Explains why this value was deprecated (if present, this will be marked deprecated in introspection)
      sig { params(value: String).returns(String) }
      def deprecation_reason=(value); end

      sig do
        params(
          graphql_name: T.untyped,
          desc: T.untyped,
          owner: T.untyped,
          deprecation_reason: T.untyped,
          description: T.untyped,
          ast_node: T.untyped,
          value: T.untyped,
          block: T.untyped
        ).returns(EnumValue)
      end
      def initialize(graphql_name, desc = nil, owner:, deprecation_reason: nil, description: nil, ast_node: nil, value: nil, &block); end

      sig { params(new_desc: T.untyped).returns(T.untyped) }
      def description(new_desc = nil); end

      sig { params(new_val: T.untyped).returns(T.untyped) }
      def value(new_val = nil); end

      # _@return_ — A runtime-ready object derived from this object
      sig { returns(GraphQL::EnumType::EnumValue) }
      def to_graphql; end

      sig { params(_ctx: T.untyped).returns(T::Boolean) }
      def visible?(_ctx); end

      sig { params(_ctx: T.untyped).returns(T::Boolean) }
      def accessible?(_ctx); end

      sig { params(_ctx: T.untyped).returns(T::Boolean) }
      def authorized?(_ctx); end

      # If this schema was parsed from a `.graphql` file (or other SDL),
      # this is the AST node that defined this part of the schema.
      sig { params(new_ast_node: T.untyped).returns(T.untyped) }
      def ast_node(new_ast_node = nil); end

      # _@return_ — A description of this member's place in the GraphQL schema
      sig { returns(String) }
      def path; end
    end

    # This module provides a function for validating GraphQL types.
    # 
    # Its {RULES} contain objects that respond to `#call(type)`. Rules are
    # looked up for given types (by class ancestry), then applied to
    # the object until an error is returned.
    class Validation
      RULES = T.let({
  GraphQL::Field => [
    Rules::NAME_IS_STRING,
    Rules::RESERVED_NAME,
    Rules::DESCRIPTION_IS_STRING_OR_NIL,
    Rules.assert_property(:deprecation_reason, String, NilClass),
    Rules.assert_property(:type, GraphQL::BaseType, GraphQL::Schema::LateBoundType),
    Rules.assert_property(:property, Symbol, NilClass),
    Rules::ARGUMENTS_ARE_STRING_TO_ARGUMENT,
    Rules::ARGUMENTS_ARE_VALID,
  ],
  GraphQL::Argument => [
    Rules::NAME_IS_STRING,
    Rules::RESERVED_NAME,
    Rules::DESCRIPTION_IS_STRING_OR_NIL,
    Rules::TYPE_IS_VALID_INPUT_TYPE,
    Rules::DEFAULT_VALUE_IS_VALID_FOR_TYPE,
  ],
  GraphQL::BaseType => [
    Rules::NAME_IS_STRING,
    Rules::RESERVED_TYPE_NAME,
    Rules::DESCRIPTION_IS_STRING_OR_NIL,
  ],
  GraphQL::ObjectType => [
    Rules::HAS_AT_LEAST_ONE_FIELD,
    Rules.assert_property_list_of(:interfaces, GraphQL::InterfaceType),
    Rules::FIELDS_ARE_VALID,
    Rules::INTERFACES_ARE_IMPLEMENTED,
  ],
  GraphQL::InputObjectType => [
    Rules::HAS_AT_LEAST_ONE_ARGUMENT,
    Rules::ARGUMENTS_ARE_STRING_TO_ARGUMENT,
    Rules::ARGUMENTS_ARE_VALID,
  ],
  GraphQL::UnionType => [
    Rules.assert_property_list_of(:possible_types, GraphQL::ObjectType),
    Rules::HAS_ONE_OR_MORE_POSSIBLE_TYPES,
  ],
  GraphQL::InterfaceType => [
    Rules::FIELDS_ARE_VALID,
  ],
  GraphQL::Schema => [
    Rules::SCHEMA_INSTRUMENTERS_ARE_VALID,
    Rules::SCHEMA_CAN_RESOLVE_TYPES,
    Rules::SCHEMA_CAN_FETCH_IDS,
    Rules::SCHEMA_CAN_GENERATE_IDS,
  ],
}, T.untyped)

      # Lookup the rules for `object` based on its class,
      # Then returns an error message or `nil`
      # 
      # _@param_ `object` — something to be validated
      # 
      # _@return_ — error message, if there was one
      sig { params(object: T.untyped).returns(T.any(String, T.untyped)) }
      def self.validate(object); end

      module Rules
        HAS_AT_LEAST_ONE_FIELD = T.let(Rules.count_at_least("field", 1, ->(type) { type.all_fields }), T.untyped)
        FIELDS_ARE_VALID = T.let(Rules.assert_named_items_are_valid("field", ->(type) { type.all_fields }), T.untyped)
        HAS_AT_LEAST_ONE_ARGUMENT = T.let(Rules.count_at_least("argument", 1, ->(type) { type.arguments }), T.untyped)
        HAS_ONE_OR_MORE_POSSIBLE_TYPES = T.let(->(type) {
  type.possible_types.length >= 1 ? nil : "must have at least one possible type"
}, T.untyped)
        NAME_IS_STRING = T.let(Rules.assert_property(:name, String), T.untyped)
        DESCRIPTION_IS_STRING_OR_NIL = T.let(Rules.assert_property(:description, String, NilClass), T.untyped)
        ARGUMENTS_ARE_STRING_TO_ARGUMENT = T.let(Rules.assert_property_mapping(:arguments, String, GraphQL::Argument), T.untyped)
        ARGUMENTS_ARE_VALID = T.let(Rules.assert_named_items_are_valid("argument", ->(type) { type.arguments.values }), T.untyped)
        DEFAULT_VALUE_IS_VALID_FOR_TYPE = T.let(->(type) {
  if !type.default_value.nil?
    coerced_value = begin
      type.type.coerce_isolated_result(type.default_value)
    rescue => ex
      ex
    end

    if coerced_value.nil? || coerced_value.is_a?(StandardError)
      msg = "default value #{type.default_value.inspect} is not valid for type #{type.type}"
      msg += " (#{coerced_value})" if coerced_value.is_a?(StandardError)
      msg
    end
  end
}, T.untyped)
        TYPE_IS_VALID_INPUT_TYPE = T.let(->(type) {
  outer_type = type.type
  inner_type = outer_type.respond_to?(:unwrap) ? outer_type.unwrap : nil

  case inner_type
  when GraphQL::ScalarType, GraphQL::InputObjectType, GraphQL::EnumType
    # OK
  else
    "type must be a valid input type (Scalar or InputObject), not #{outer_type.class} (#{outer_type})"
  end
}, T.untyped)
        SCHEMA_CAN_RESOLVE_TYPES = T.let(->(schema) {
  if schema.types.values.any? { |type| type.kind.abstract? } && schema.resolve_type_proc.nil?
    "schema contains Interfaces or Unions, so you must define a `resolve_type -> (obj, ctx) { ... }` function"
  else
    # :+1:
  end
}, T.untyped)
        SCHEMA_CAN_FETCH_IDS = T.let(->(schema) {
  has_node_field = schema.query && schema.query.all_fields.any?(&:relay_node_field)
  if has_node_field && schema.object_from_id_proc.nil?
    "schema contains `node(id:...)` field, so you must define a `object_from_id -> (id, ctx) { ... }` function"
  else
    # :rocket:
  end
}, T.untyped)
        SCHEMA_CAN_GENERATE_IDS = T.let(->(schema) {
  has_id_field = schema.types.values.any? { |t| t.kind.fields? && t.all_fields.any? { |f| f.resolve_proc.is_a?(GraphQL::Relay::GlobalIdResolve) } }
  if has_id_field && schema.id_from_object_proc.nil?
    "schema contains `global_id_field`, so you must define a `id_from_object -> (obj, type, ctx) { ... }` function"
  else
    # :ok_hand:
  end
}, T.untyped)
        SCHEMA_INSTRUMENTERS_ARE_VALID = T.let(->(schema) {
  errs = []
  schema.instrumenters[:query].each do |inst|
    if !inst.respond_to?(:before_query) || !inst.respond_to?(:after_query)
      errs << "`instrument(:query, #{inst})` is invalid: must respond to `before_query(query)` and `after_query(query)` "
    end
  end

  schema.instrumenters[:field].each do |inst|
    if !inst.respond_to?(:instrument)
      errs << "`instrument(:field, #{inst})` is invalid: must respond to `instrument(type, field)`"
    end
  end

  if errs.any?
    errs.join("Invalid instrumenters:\n" + errs.join("\n"))
  else
    nil
  end
}, T.untyped)
        RESERVED_TYPE_NAME = T.let(->(type) {
  if type.name.start_with?('__') && !type.introspection?
    # TODO: make this a hard failure in a later version
    warn("Name #{type.name.inspect} must not begin with \"__\", which is reserved by GraphQL introspection.")
    nil
  else
    # ok name
  end
}, T.untyped)
        RESERVED_NAME = T.let(->(named_thing) {
  if named_thing.name.start_with?('__')
    # TODO: make this a hard failure in a later version
    warn("Name #{named_thing.name.inspect} must not begin with \"__\", which is reserved by GraphQL introspection.")
    nil
  else
    # no worries
  end
}, T.untyped)
        INTERFACES_ARE_IMPLEMENTED = T.let(->(obj_type) {
  field_errors = []
  obj_type.interfaces.each do |interface_type|
    interface_type.fields.each do |field_name, field_defn|
      object_field = obj_type.get_field(field_name)
      if object_field.nil?
        field_errors << %|"#{field_name}" is required by #{interface_type.name} but not implemented by #{obj_type.name}|
      elsif !GraphQL::Execution::Typecast.subtype?(field_defn.type, object_field.type)
        field_errors << %|"#{field_name}" is required by #{interface_type.name} to return #{field_defn.type} but #{obj_type.name}.#{field_name} returns #{object_field.type}|
      else
        field_defn.arguments.each do |arg_name, arg_defn|
          object_field_arg = object_field.arguments[arg_name]
          if object_field_arg.nil?
            field_errors << %|"#{arg_name}" argument is required by #{interface_type.name}.#{field_name} but not accepted by #{obj_type.name}.#{field_name}|
          elsif arg_defn.type != object_field_arg.type
            field_errors << %|"#{arg_name}" is required by #{interface_type.name}.#{field_defn.name} to accept #{arg_defn.type} but #{obj_type.name}.#{field_name} accepts #{object_field_arg.type} for "#{arg_name}"|
          end
        end

        object_field.arguments.each do |arg_name, arg_defn|
          if field_defn.arguments[arg_name].nil? && arg_defn.type.is_a?(GraphQL::NonNullType)
            field_errors << %|"#{arg_name}" is not accepted by #{interface_type.name}.#{field_name} but required by #{obj_type.name}.#{field_name}|
          end
        end
      end
    end
  end
  if field_errors.any?
    "#{obj_type.name} failed to implement some interfaces: #{field_errors.join(", ")}"
  else
    nil
  end
}, T.untyped)

        # _@param_ `property_name` — The method to validate
        # 
        # _@param_ `allowed_classes` — Classes which the return value may be an instance of
        # 
        # _@return_ — A proc which will validate the input by calling `property_name` and asserting it is an instance of one of `allowed_classes`
        sig { params(property_name: Symbol, allowed_classes: Class).returns(Proc) }
        def self.assert_property(property_name, *allowed_classes); end

        # _@param_ `property_name` — The method whose return value will be validated
        # 
        # _@param_ `from_class` — The class for keys in the return value
        # 
        # _@param_ `to_class` — The class for values in the return value
        # 
        # _@return_ — A proc to validate that validates the input by calling `property_name` and asserting that the return value is a Hash of `{from_class => to_class}` pairs
        sig { params(property_name: Symbol, from_class: Class, to_class: Class).returns(Proc) }
        def self.assert_property_mapping(property_name, from_class, to_class); end

        # _@param_ `property_name` — The method whose return value will be validated
        # 
        # _@param_ `list_member_class` — The class which each member of the returned array should be an instance of
        # 
        # _@return_ — A proc to validate the input by calling `property_name` and asserting that the return is an Array of `list_member_class` instances
        sig { params(property_name: Symbol, list_member_class: Class).returns(Proc) }
        def self.assert_property_list_of(property_name, list_member_class); end

        sig { params(item_name: T.untyped, minimum_count: T.untyped, get_items_proc: T.untyped).returns(T.untyped) }
        def self.count_at_least(item_name, minimum_count, get_items_proc); end

        sig { params(item_name: T.untyped, get_items_proc: T.untyped).returns(T.untyped) }
        def self.assert_named_items_are_valid(item_name, get_items_proc); end
      end
    end

    class InputObject < GraphQL::Schema::Member
      include GraphQL::Dig
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend Forwardable
      extend GraphQL::Schema::Member::HasArguments
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig do
        params(
          values: T.untyped,
          context: T.untyped,
          defaults_used: T.untyped,
          ruby_kwargs: T.untyped
        ).returns(InputObject)
      end
      def initialize(values = nil, context:, defaults_used:, ruby_kwargs: nil); end

      # _@return_ — The context for this query
      sig { returns(GraphQL::Query::Context) }
      def context; end

      # _@return_ — The underlying arguments instance
      sig { returns(GraphQL::Query::Arguments) }
      def arguments; end

      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def to_hash; end

      sig { params(value: T.untyped).returns(T.untyped) }
      def unwrap_value(value); end

      # Lookup a key on this object, it accepts new-style underscored symbols
      # Or old-style camelized identifiers.
      # 
      # _@param_ `key` — 
      sig { params(key: T.any(Symbol, String)).returns(T.untyped) }
      def [](key); end

      sig { params(key: T.untyped).returns(T::Boolean) }
      def key?(key); end

      # A copy of the Ruby-style hash
      sig { returns(T.untyped) }
      def to_kwargs; end

      sig { returns(T.untyped) }
      def self.arguments_class; end

      sig { params(value: T.untyped).returns(T.untyped) }
      def self.arguments_class=(value); end

      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(T.untyped) }
      def self.argument(*args, **kwargs, &block); end

      sig { returns(T.untyped) }
      def self.to_graphql; end

      sig { returns(T.untyped) }
      def self.kind; end

      # Register this argument with the class.
      # 
      # _@param_ `arg_defn` — 
      sig { params(arg_defn: GraphQL::Schema::Argument).returns(GraphQL::Schema::Argument) }
      def self.add_argument(arg_defn); end

      # _@return_ — Hash<String => GraphQL::Schema::Argument] Arguments defined on this thing, keyed by name. Includes inherited definitions
      sig { returns(T.untyped) }
      def self.arguments; end

      # _@param_ `new_arg_class` — A class to use for building argument definitions
      sig { params(new_arg_class: T.nilable(Class)).returns(T.untyped) }
      def self.argument_class(new_arg_class = nil); end

      sig { returns(T.untyped) }
      def self.own_arguments; end

      # implemented using the old activesupport #dig instead of the ruby built-in
      # so we can use some of the magic in Schema::InputObject and Query::Arguments
      # to handle stringified/symbolized keys.
      # 
      # _@param_ `args` — rgs [Array<[String, Symbol>] Retrieves the value object corresponding to the each key objects repeatedly
      sig { params(own_key: T.untyped, rest_keys: T.untyped).returns(Object) }
      def dig(own_key, *rest_keys); end
    end

    # This class can be extended to create fields on your subscription root.
    # 
    # It provides hooks for the different parts of the subscription lifecycle:
    # 
    # - `#authorized?`: called before initial subscription and subsequent updates
    # - `#subscribe`: called for the initial subscription
    # - `#update`: called for subsequent update
    # 
    # Also, `#unsubscribe` terminates the subscription.
    class Subscription < GraphQL::Schema::Resolver
      extend GraphQL::Schema::Resolver::HasPayloadType
      extend GraphQL::Schema::Member::HasFields
      READING_SCOPE = T.let(::Object.new, T.untyped)
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(object: T.untyped, context: T.untyped).returns(Subscription) }
      def initialize(object:, context:); end

      # Implement the {Resolve} API
      sig { params(args: T.untyped).returns(T.untyped) }
      def resolve(**args); end

      # Wrap the user-defined `#subscribe` hook
      sig { params(args: T.untyped).returns(T.untyped) }
      def resolve_subscribe(args); end

      # Default implementation returns the root object.
      # Override it to return an object or
      # `:no_response` to return nothing.
      # 
      # The default is `:no_response`.
      sig { params(args: T.untyped).returns(T.untyped) }
      def subscribe(args = {}); end

      # Wrap the user-provided `#update` hook
      sig { params(args: T.untyped).returns(T.untyped) }
      def resolve_update(args); end

      # The default implementation returns the root object.
      # Override it to return `:no_update` if you want to
      # skip updates sometimes. Or override it to return a different object.
      sig { params(args: T.untyped).returns(T.untyped) }
      def update(args = {}); end

      # If an argument is flagged with `loads:` and no object is found for it,
      # remove this subscription (assuming that the object was deleted in the meantime,
      # or that it became inaccessible).
      sig { params(err: T.untyped).returns(T.untyped) }
      def load_application_object_failed(err); end

      # Call this to halt execution and remove this subscription from the system
      sig { returns(T.untyped) }
      def unsubscribe; end

      sig { params(new_scope: T.untyped).returns(T.untyped) }
      def self.subscription_scope(new_scope = READING_SCOPE); end

      # Overriding Resolver#field_options to include subscription_scope
      sig { returns(T.untyped) }
      def self.field_options; end

      # Add a field to this object or interface with the given definition
      # 
      # _@see_ `{GraphQL::Schema::Field#initialize}` — for method signature
      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(GraphQL::Schema::Field) }
      def self.field(*args, **kwargs, &block); end

      # _@return_ — Fields on this object, keyed by name, including inherited fields
      sig { returns(T::Hash[String, GraphQL::Schema::Field]) }
      def self.fields; end

      sig { params(field_name: T.untyped).returns(T.untyped) }
      def self.get_field(field_name); end

      # Register this field with the class, overriding a previous one if needed.
      # 
      # _@param_ `field_defn` — 
      sig { params(field_defn: GraphQL::Schema::Field).void }
      def self.add_field(field_defn); end

      # _@return_ — The class to initialize when adding fields to this kind of schema member
      sig { params(new_field_class: T.untyped).returns(Class) }
      def self.field_class(new_field_class = nil); end

      sig { params(field_name: T.untyped).returns(T.untyped) }
      def self.global_id_field(field_name); end

      # _@return_ — Fields defined on this class _specifically_, not parent classes
      sig { returns(T::Array[GraphQL::Schema::Field]) }
      def self.own_fields; end

      # Call this method to get the derived return type of the mutation,
      # or use it as a configuration method to assign a return type
      # instead of generating one.
      # 
      # _@param_ `new_payload_type` — If a type definition class is provided, it will be used as the return type of the mutation field
      # 
      # _@return_ — The object type which this mutation returns.
      sig { params(new_payload_type: T.nilable(Class)).returns(Class) }
      def self.payload_type(new_payload_type = nil); end

      # An object class to use for deriving return types
      # 
      # _@param_ `new_class` — Defaults to {GraphQL::Schema::Object}
      sig { params(new_class: T.nilable(Class)).returns(Class) }
      def self.object_class(new_class = nil); end

      # Build a subclass of {.object_class} based on `self`.
      # This value will be cached as `{.payload_type}`.
      # Override this hook to customize return type generation.
      sig { returns(T.untyped) }
      def self.generate_payload_type; end

      class EarlyTerminationError < StandardError
      end

      # Raised when `unsubscribe` is called; caught by `subscriptions.rb`
      class UnsubscribedError < GraphQL::Schema::Subscription::EarlyTerminationError
      end

      # Raised when `no_update` is returned; caught by `subscriptions.rb`
      class NoUpdateError < GraphQL::Schema::Subscription::EarlyTerminationError
      end
    end

    # Find the members of a union or interface within a given schema.
    # 
    # (Although its members never change, unions are handled this way to simplify execution code.)
    # 
    # Internally, the calculation is cached. It's assumed that schema members _don't_ change after creating the schema!
    # 
    # @example Get an interface's possible types
    #   possible_types = GraphQL::Schema::PossibleTypes(MySchema)
    #   possible_types.possible_types(MyInterface)
    #   # => [MyObjectType, MyOtherObjectType]
    class PossibleTypes
      sig { params(schema: T.untyped).returns(PossibleTypes) }
      def initialize(schema); end

      sig { params(type_defn: T.untyped).returns(T.untyped) }
      def possible_types(type_defn); end
    end

    # @api private
    module Base64Encoder
      sig { params(unencoded_text: T.untyped, nonce: T.untyped).returns(T.untyped) }
      def self.encode(unencoded_text, nonce: false); end

      sig { params(encoded_text: T.untyped, nonce: T.untyped).returns(T.untyped) }
      def self.decode(encoded_text, nonce: false); end
    end

    # Extend this class to make field-level customizations to resolve behavior.
    # 
    # When a extension is added to a field with `extension(MyExtension)`, a `MyExtension` instance
    # is created, and its hooks are applied whenever that field is called.
    # 
    # The instance is frozen so that instance variables aren't modified during query execution,
    # which could cause all kinds of issues due to race conditions.
    class FieldExtension
      sig { returns(GraphQL::Schema::Field) }
      def field; end

      sig { returns(T.untyped) }
      def options; end

      # Called when the extension is mounted with `extension(name, options)`.
      # The instance is frozen to avoid improper use of state during execution.
      # 
      # _@param_ `field` — The field where this extension was mounted
      # 
      # _@param_ `options` — The second argument to `extension`, or `{}` if nothing was passed.
      sig { params(field: GraphQL::Schema::Field, options: T.untyped).returns(FieldExtension) }
      def initialize(field:, options:); end

      # Called when this extension is attached to a field.
      # The field definition may be extended during this method.
      sig { void }
      def apply; end

      # Called before resolving {#field}. It should either:
      # 
      # - `yield` values to continue execution; OR
      # - return something else to shortcut field execution.
      # 
      # Whatever this method returns will be used for execution.
      # 
      # _@param_ `object` — The object the field is being resolved on
      # 
      # _@param_ `arguments` — Ruby keyword arguments for resolving this field
      # 
      # _@param_ `context` — the context for this query
      # 
      # _@return_ — The return value for this field.
      sig { params(object: T.untyped, arguments: T::Hash[T.untyped, T.untyped], context: Query::Context).returns(T.untyped) }
      def resolve(object:, arguments:, context:); end

      # Called after {#field} was resolved, and after any lazy values (like `Promise`s) were synced,
      # but before the value was added to the GraphQL response.
      # 
      # Whatever this hook returns will be used as the return value.
      # 
      # _@param_ `object` — The object the field is being resolved on
      # 
      # _@param_ `arguments` — Ruby keyword arguments for resolving this field
      # 
      # _@param_ `context` — the context for this query
      # 
      # _@param_ `value` — Whatever the field previously returned
      # 
      # _@param_ `memo` — The third value yielded by {#resolve}, or `nil` if there wasn't one
      # 
      # _@return_ — The return value for this field.
      sig do
        params(
          object: T.untyped,
          arguments: T::Hash[T.untyped, T.untyped],
          context: Query::Context,
          value: T.untyped,
          memo: T.untyped
        ).returns(T.untyped)
      end
      def after_resolve(object:, arguments:, context:, value:, memo:); end
    end

    # A stand-in for a type which will be resolved in a given schema, by name.
    # TODO: support argument types too, make this a public API somehow
    # @api Private
    class LateBoundType
      sig { returns(T.untyped) }
      def name; end

      sig { params(local_name: T.untyped).returns(LateBoundType) }
      def initialize(local_name); end

      sig { returns(T.untyped) }
      def unwrap; end

      sig { returns(T.untyped) }
      def to_non_null_type; end

      sig { returns(T.untyped) }
      def to_list_type; end

      sig { returns(T.untyped) }
      def inspect; end
    end

    # @api private
    module TypeExpression
      # Fetch a type from a type map by its AST specification.
      # Return `nil` if not found.
      # 
      # _@param_ `types` — 
      # 
      # _@param_ `ast_node` — 
      sig { params(types: T.untyped, ast_node: GraphQL::Language::Nodes::AbstractNode).returns(T.nilable(GraphQL::BaseType)) }
      def self.build_type(types, ast_node); end

      sig { params(types: T.untyped, ast_node: T.untyped).returns(T.untyped) }
      def self.type_from_ast(types, ast_node); end

      sig { params(of_type: T.untyped, wrapper: T.untyped).returns(T.untyped) }
      def self.wrap_type(of_type, wrapper); end
    end

    # Given {steps} and {arguments}, call steps in order, passing `(*arguments, next_step)`.
    # 
    # Steps should call `next_step.call` to continue the chain, or _not_ call it to stop the chain.
    class MiddlewareChain
      extend Forwardable

      # _@return_ — Steps in this chain, will be called with arguments and `next_middleware`
      sig { returns(T::Array[T.untyped]) }
      def steps; end

      # _@return_ — Steps in this chain, will be called with arguments and `next_middleware`
      sig { returns(T::Array[T.untyped]) }
      def final_step; end

      sig { params(steps: T.untyped, final_step: T.untyped).returns(MiddlewareChain) }
      def initialize(steps: [], final_step: nil); end

      sig { params(other: T.untyped).returns(T.untyped) }
      def initialize_copy(other); end

      sig { params(callable: T.untyped).returns(T.untyped) }
      def <<(callable); end

      sig { params(callable: T.untyped).returns(T.untyped) }
      def push(callable); end

      sig { params(other: T.untyped).returns(T.untyped) }
      def ==(other); end

      sig { params(arguments: T.untyped).returns(T.untyped) }
      def invoke(arguments); end

      sig { params(callables: T.untyped).returns(T.untyped) }
      def concat(callables); end

      sig { params(index: T.untyped, arguments: T.untyped).returns(T.untyped) }
      def invoke_core(index, arguments); end

      sig { params(callable: T.untyped).returns(T.untyped) }
      def add_middleware(callable); end

      sig { params(callable: T.untyped).returns(T.untyped) }
      def wrap(callable); end

      # TODO: Remove this code once deprecated middleware becomes unsupported
      class MiddlewareWrapper
        # Returns the value of attribute callable
        sig { returns(T.untyped) }
        def callable; end

        sig { params(callable: T.untyped).returns(MiddlewareWrapper) }
        def initialize(callable); end

        sig { params(args: T.untyped, next_middleware: T.untyped).returns(T.untyped) }
        def call(*args, &next_middleware); end
      end
    end

    # - Store a table of errors & handlers
    # - Rescue errors in a middleware chain, then check for a handler
    # - If a handler is found, use it & return a {GraphQL::ExecutionError}
    # - If no handler is found, re-raise the error
    class RescueMiddleware
      # _@return_ — `{class => proc}` pairs for handling errors
      sig { returns(T::Hash[T.untyped, T.untyped]) }
      def rescue_table; end

      sig { returns(RescueMiddleware) }
      def initialize; end

      # _@param_ `error_classes` — one or more classes of errors to rescue from
      # 
      # Rescue from not-found by telling the user
      # ```ruby
      # MySchema.rescue_from(ActiveRecord::RecordNotFound) { "An item could not be found" }
      # ```
      sig { params(error_classes: Class, block: T.proc.params(an: Exception).returns(String)).returns(T.untyped) }
      def rescue_from(*error_classes, &block); end

      # Remove the handler for `error_classs`
      # 
      # _@param_ `error_class` — the error class whose handler should be removed
      sig { params(error_classes: Class).returns(T.untyped) }
      def remove_handler(*error_classes); end

      # Implement the requirement for {GraphQL::Schema::MiddlewareChain}
      sig { params(args: T.untyped).returns(T.untyped) }
      def call(*args); end

      sig { params(err: T.untyped).returns(T.untyped) }
      def attempt_rescue(err); end
    end

    module DefaultTypeError
      sig { params(type_error: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.call(type_error, ctx); end
    end

    class InvalidTypeError < GraphQL::Error
    end

    # This middleware will stop resolving new fields after `max_seconds` have elapsed.
    # After the time has passed, any remaining fields will be `nil`, with errors added
    # to the `errors` key. Any already-resolved fields will be in the `data` key, so
    # you'll get a partial response.
    # 
    # You can provide a block which will be called with any timeout errors that occur.
    # 
    # Note that this will stop a query _in between_ field resolutions, but
    # it doesn't interrupt long-running `resolve` functions. Be sure to use
    # timeout options for external connections. For more info, see
    # www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/
    # 
    # @example Stop resolving fields after 2 seconds
    #   MySchema.middleware << GraphQL::Schema::TimeoutMiddleware.new(max_seconds: 2)
    # 
    # @example Notifying Bugsnag on a timeout
    #   MySchema.middleware << GraphQL::Schema::TimeoutMiddleware(max_seconds: 1.5) do |timeout_error, query|
    #    Bugsnag.notify(timeout_error, {query_string: query_ctx.query.query_string})
    #   end
    class TimeoutMiddleware
      # _@param_ `max_seconds` — how many seconds the query should be allowed to resolve new fields
      sig { params(max_seconds: Numeric, context_key: T.untyped, block: T.untyped).returns(TimeoutMiddleware) }
      def initialize(max_seconds:, context_key: nil, &block); end

      sig do
        params(
          parent_type: T.untyped,
          parent_object: T.untyped,
          field_definition: T.untyped,
          field_args: T.untyped,
          query_context: T.untyped
        ).returns(T.untyped)
      end
      def call(parent_type, parent_object, field_definition, field_args, query_context); end

      # This is called when a field _would_ be resolved, except that we're over the time limit.
      # 
      # _@return_ — An error whose message will be added to the `errors` key
      sig do
        params(
          parent_type: T.untyped,
          parent_object: T.untyped,
          field_definition: T.untyped,
          field_args: T.untyped,
          field_context: T.untyped
        ).returns(GraphQL::Schema::TimeoutMiddleware::TimeoutError)
      end
      def on_timeout(parent_type, parent_object, field_definition, field_args, field_context); end

      # This behaves like {GraphQL::Query} but {#context} returns
      # the _field-level_ context, not the query-level context.
      # This means you can reliably get the `irep_node` and `path`
      # from it after the fact.
      class TimeoutQueryProxy < SimpleDelegator
        sig { params(query: T.untyped, ctx: T.untyped).returns(TimeoutQueryProxy) }
        def initialize(query, ctx); end

        # Returns the value of attribute context
        sig { returns(T.untyped) }
        def context; end
      end

      # This error is raised when a query exceeds `max_seconds`.
      # Since it's a child of {GraphQL::ExecutionError},
      # its message will be added to the response's `errors` key.
      # 
      # To raise an error that will stop query resolution, use a custom block
      # to take this error and raise a new one which _doesn't_ descend from {GraphQL::ExecutionError},
      # such as `RuntimeError`.
      class TimeoutError < GraphQL::ExecutionError
        sig { params(parent_type: T.untyped, field_defn: T.untyped).returns(TimeoutError) }
        def initialize(parent_type, field_defn); end
      end
    end

    module UniqueWithinType
      # Returns the value of attribute default_id_separator
      sig { returns(T.untyped) }
      def self.default_id_separator; end

      # Sets the attribute default_id_separator
      # 
      # _@param_ `value` — the value to set the attribute default_id_separator to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self.default_id_separator=(value); end

      # _@param_ `type_name`
      # 
      # _@param_ `object_value`
      # 
      # _@return_ — a unique, opaque ID generated as a function of the two inputs
      sig { params(type_name: String, object_value: T.untyped, separator: T.untyped).returns(String) }
      def encode(type_name, object_value, separator: self.default_id_separator); end

      # _@param_ `type_name` — 
      # 
      # _@param_ `object_value` — 
      # 
      # _@return_ — a unique, opaque ID generated as a function of the two inputs
      sig { params(type_name: String, object_value: T.untyped, separator: T.untyped).returns(String) }
      def self.encode(type_name, object_value, separator: self.default_id_separator); end

      # _@param_ `node_id` — A unique ID generated by {.encode}
      # 
      # _@return_ — The type name & value passed to {.encode}
      sig { params(node_id: String, separator: T.untyped).returns(T::Array[[String, String]]) }
      def decode(node_id, separator: self.default_id_separator); end

      # _@param_ `node_id` — A unique ID generated by {.encode}
      # 
      # _@return_ — The type name & value passed to {.encode}
      sig { params(node_id: String, separator: T.untyped).returns(T::Array[[String, String]]) }
      def self.decode(node_id, separator: self.default_id_separator); end
    end

    # In early GraphQL versions, errors would be "automatically"
    # rescued and replaced with `"Internal error"`. That behavior
    # was undesirable but this middleware is offered for people who
    # want to preserve it.
    # 
    # It has a couple of differences from the previous behavior:
    # 
    # - Other parts of the query _will_ be run (previously,
    #   execution would stop when the error was raised and the result
    #   would have no `"data"` key at all)
    # - The entry in {Query::Context#errors} is a {GraphQL::ExecutionError}, _not_
    #   the originally-raised error.
    # - The entry in the `"errors"` key includes the location of the field
    #   which raised the errors.
    # 
    # @example Use CatchallMiddleware with your schema
    #     # All errors will be suppressed and replaced with "Internal error" messages
    #     MySchema.middleware << GraphQL::Schema::CatchallMiddleware
    module CatchallMiddleware
      MESSAGE = T.let("Internal error", T.untyped)

      # Rescue any error and replace it with a {GraphQL::ExecutionError}
      # whose message is {MESSAGE}
      sig do
        params(
          parent_type: T.untyped,
          parent_object: T.untyped,
          field_definition: T.untyped,
          field_args: T.untyped,
          query_context: T.untyped
        ).returns(T.untyped)
      end
      def self.call(parent_type, parent_object, field_definition, field_args, query_context); end
    end

    module DefaultParseError
      sig { params(parse_error: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.call(parse_error, ctx); end
    end

    module FindInheritedValue
      sig { params(child_cls: T.untyped).returns(T.untyped) }
      def self.extended(child_cls); end

      sig { params(child_cls: T.untyped).returns(T.untyped) }
      def self.included(child_cls); end

      sig { params(method_name: T.untyped, default_value: T.untyped).returns(T.untyped) }
      def find_inherited_value(method_name, default_value = nil); end

      module EmptyObjects
        EMPTY_HASH = T.let({}.freeze, T.untyped)
        EMPTY_ARRAY = T.let([].freeze, T.untyped)
      end
    end

    class IntrospectionSystem
      # Returns the value of attribute schema_type
      sig { returns(T.untyped) }
      def schema_type; end

      # Returns the value of attribute type_type
      sig { returns(T.untyped) }
      def type_type; end

      # Returns the value of attribute typename_field
      sig { returns(T.untyped) }
      def typename_field; end

      sig { params(schema: T.untyped).returns(IntrospectionSystem) }
      def initialize(schema); end

      sig { returns(T.untyped) }
      def object_types; end

      sig { returns(T.untyped) }
      def entry_points; end

      sig { params(name: T.untyped).returns(T.untyped) }
      def entry_point(name:); end

      sig { returns(T.untyped) }
      def dynamic_fields; end

      sig { params(name: T.untyped).returns(T.untyped) }
      def dynamic_field(name:); end

      sig { params(class_name: T.untyped).returns(T.untyped) }
      def load_constant(class_name); end

      sig { params(class_sym: T.untyped).returns(T.untyped) }
      def get_fields_from_class(class_sym:); end

      class PerFieldProxyResolve
        sig { params(object_class: T.untyped, inner_resolve: T.untyped).returns(PerFieldProxyResolve) }
        def initialize(object_class:, inner_resolve:); end

        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def call(obj, args, ctx); end
      end
    end

    module BuildFromDefinition
      DefaultParser = T.let(GraphQL::Language::Parser, T.untyped)

      sig { params(definition_string: T.untyped, default_resolve: T.untyped, parser: T.untyped).returns(T.untyped) }
      def self.from_definition(definition_string, default_resolve:, parser: DefaultParser); end

      # @api private
      module DefaultResolve
        sig do
          params(
            type: T.untyped,
            field: T.untyped,
            obj: T.untyped,
            args: T.untyped,
            ctx: T.untyped
          ).returns(T.untyped)
        end
        def self.call(type, field, obj, args, ctx); end
      end

      # @api private
      module Builder
        extend GraphQL::Schema::BuildFromDefinition::Builder
        NullResolveType = T.let(->(type, obj, ctx) {
  raise(GraphQL::RequiredImplementationMissingError, "Generated Schema cannot use Interface or Union types for execution. Implement resolve_type on your resolver.")
}, T.untyped)

        sig { params(document: T.untyped, default_resolve: T.untyped).returns(T.untyped) }
        def build(document, default_resolve: DefaultResolve); end

        sig { params(enum_type_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def build_enum_type(enum_type_definition, type_resolver); end

        sig { params(directives: T.untyped).returns(T.untyped) }
        def build_deprecation_reason(directives); end

        sig { params(scalar_type_definition: T.untyped, type_resolver: T.untyped, default_resolve: T.untyped).returns(T.untyped) }
        def build_scalar_type(scalar_type_definition, type_resolver, default_resolve:); end

        sig { params(union_type_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def build_union_type(union_type_definition, type_resolver); end

        sig { params(object_type_definition: T.untyped, type_resolver: T.untyped, default_resolve: T.untyped).returns(T.untyped) }
        def build_object_type(object_type_definition, type_resolver, default_resolve:); end

        sig { params(input_object_type_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def build_input_object_type(input_object_type_definition, type_resolver); end

        sig { params(default_value: T.untyped).returns(T.untyped) }
        def build_default_value(default_value); end

        sig { params(type_class: T.untyped, arguments: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def build_arguments(type_class, arguments, type_resolver); end

        sig { params(directive_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def build_directive(directive_definition, type_resolver); end

        sig { params(interface_type_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def build_interface_type(interface_type_definition, type_resolver); end

        sig do
          params(
            owner: T.untyped,
            field_definitions: T.untyped,
            type_resolver: T.untyped,
            default_resolve: T.untyped
          ).returns(T.untyped)
        end
        def build_fields(owner, field_definitions, type_resolver, default_resolve:); end

        sig { params(types: T.untyped, ast_node: T.untyped).returns(T.untyped) }
        def resolve_type(types, ast_node); end

        sig { params(type: T.untyped).returns(T.untyped) }
        def resolve_type_name(type); end

        sig { params(document: T.untyped, default_resolve: T.untyped).returns(T.untyped) }
        def self.build(document, default_resolve: DefaultResolve); end

        sig { params(enum_type_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def self.build_enum_type(enum_type_definition, type_resolver); end

        sig { params(directives: T.untyped).returns(T.untyped) }
        def self.build_deprecation_reason(directives); end

        sig { params(scalar_type_definition: T.untyped, type_resolver: T.untyped, default_resolve: T.untyped).returns(T.untyped) }
        def self.build_scalar_type(scalar_type_definition, type_resolver, default_resolve:); end

        sig { params(union_type_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def self.build_union_type(union_type_definition, type_resolver); end

        sig { params(object_type_definition: T.untyped, type_resolver: T.untyped, default_resolve: T.untyped).returns(T.untyped) }
        def self.build_object_type(object_type_definition, type_resolver, default_resolve:); end

        sig { params(input_object_type_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def self.build_input_object_type(input_object_type_definition, type_resolver); end

        sig { params(default_value: T.untyped).returns(T.untyped) }
        def self.build_default_value(default_value); end

        sig { params(type_class: T.untyped, arguments: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def self.build_arguments(type_class, arguments, type_resolver); end

        sig { params(directive_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def self.build_directive(directive_definition, type_resolver); end

        sig { params(interface_type_definition: T.untyped, type_resolver: T.untyped).returns(T.untyped) }
        def self.build_interface_type(interface_type_definition, type_resolver); end

        sig do
          params(
            owner: T.untyped,
            field_definitions: T.untyped,
            type_resolver: T.untyped,
            default_resolve: T.untyped
          ).returns(T.untyped)
        end
        def self.build_fields(owner, field_definitions, type_resolver, default_resolve:); end

        sig { params(types: T.untyped, ast_node: T.untyped).returns(T.untyped) }
        def self.resolve_type(types, ast_node); end

        sig { params(type: T.untyped).returns(T.untyped) }
        def self.resolve_type_name(type); end
      end

      # Wrap a user-provided hash of resolution behavior for easy access at runtime.
      # 
      # Coerce scalar values by:
      # - Checking for a function in the map like `{ Date: { coerce_input: ->(val, ctx) { ... }, coerce_result: ->(val, ctx) { ... } } }`
      # - Falling back to a passthrough
      # 
      # Interface/union resolution can be provided as a `resolve_type:` key.
      # 
      # @api private
      class ResolveMap
        sig { params(user_resolve_hash: T.untyped).returns(ResolveMap) }
        def initialize(user_resolve_hash); end

        sig do
          params(
            type: T.untyped,
            field: T.untyped,
            obj: T.untyped,
            args: T.untyped,
            ctx: T.untyped
          ).returns(T.untyped)
        end
        def call(type, field, obj, args, ctx); end

        sig { params(type: T.untyped, value: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def coerce_input(type, value, ctx); end

        sig { params(type: T.untyped, value: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def coerce_result(type, value, ctx); end

        module NullScalarCoerce
          sig { params(val: T.untyped, _ctx: T.untyped).returns(T.untyped) }
          def self.call(val, _ctx); end
        end

        class DefaultResolve
          sig { params(field_map: T.untyped, field_name: T.untyped).returns(DefaultResolve) }
          def initialize(field_map, field_name); end

          # Make some runtime checks about
          # how `obj` implements the `field_name`.
          # 
          # Create a new resolve function according to that implementation, then:
          #   - update `field_map` with this implementation
          #   - call the implementation now (to satisfy this field execution)
          # 
          # If `obj` doesn't implement `field_name`, raise an error.
          sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
          def call(obj, args, ctx); end
        end
      end
    end

    # Mutations that extend this base class get some conventions added for free:
    # 
    # - An argument called `clientMutationId` is _always_ added, but it's not passed
    #   to the resolve method. The value is re-inserted to the response. (It's for
    #   client libraries to manage optimistic updates.)
    # - The returned object type always has a field called `clientMutationId` to support that.
    # - The mutation accepts one argument called `input`, `argument`s defined in the mutation
    #   class are added to that input object, which is generated by the mutation.
    # 
    # These conventions were first specified by Relay Classic, but they come in handy:
    # 
    # - `clientMutationId` supports optimistic updates and cache rollbacks on the client
    # - using a single `input:` argument makes it easy to post whole JSON objects to the mutation
    #   using one GraphQL variable (`$input`) instead of making a separate variable for each argument.
    # 
    # @see {GraphQL::Schema::Mutation} for an example, it's basically the same.
    class RelayClassicMutation < GraphQL::Schema::Mutation
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # Override {GraphQL::Schema::Resolver#resolve_with_support} to
      # delete `client_mutation_id` from the kwargs.
      sig { params(inputs: T.untyped).returns(T.untyped) }
      def resolve_with_support(**inputs); end

      # The base class for generated input object types
      # 
      # _@param_ `new_class` — The base class to use for generating input object definitions
      # 
      # _@return_ — The base class for this mutation's generated input object (default is {GraphQL::Schema::InputObject})
      sig { params(new_class: T.nilable(Class)).returns(Class) }
      def self.input_object_class(new_class = nil); end

      # _@param_ `new_input_type` — If provided, it configures this mutation to accept `new_input_type` instead of generating an input type
      # 
      # _@return_ — The generated {Schema::InputObject} class for this mutation's `input`
      sig { params(new_input_type: T.nilable(Class)).returns(Class) }
      def self.input_type(new_input_type = nil); end

      # Extend {Schema::Mutation.field_options} to add the `input` argument
      sig { returns(T.untyped) }
      def self.field_options; end

      # Generate the input type for the `input:` argument
      # To customize how input objects are generated, override this method
      # 
      # _@return_ — a subclass of {.input_object_class}
      sig { returns(Class) }
      def self.generate_input_type; end
    end
  end

  class Railtie < Rails::Railtie
  end

  # Library entry point for performance metric reporting.
  # 
  # __Warning:__ Installing/uninstalling tracers is not thread-safe. Do it during application boot only.
  # 
  # @example Sending custom events
  #   GraphQL::Tracing.trace("my_custom_event", { ... }) do
  #     # do stuff ...
  #   end
  # 
  # @example Adding a tracer to a schema
  #  MySchema = GraphQL::Schema.define do
  #    tracer MyTracer # <= responds to .trace(key, data, &block)
  #  end
  # 
  # @example Adding a tracer to a single query
  #   MySchema.execute(query_str, context: { backtrace: true })
  # 
  # Events:
  # 
  # Key | Metadata
  # ----|---------
  # lex | `{ query_string: String }`
  # parse | `{ query_string: String }`
  # validate | `{ query: GraphQL::Query, validate: Boolean }`
  # analyze_multiplex |  `{ multiplex: GraphQL::Execution::Multiplex }`
  # analyze_query | `{ query: GraphQL::Query }`
  # execute_multiplex | `{ multiplex: GraphQL::Execution::Multiplex }`
  # execute_query | `{ query: GraphQL::Query }`
  # execute_query_lazy | `{ query: GraphQL::Query?, multiplex: GraphQL::Execution::Multiplex? }`
  # execute_field | `{ context: GraphQL::Query::Context::FieldResolutionContext?, owner: Class?, field: GraphQL::Schema::Field?, query: GraphQL::Query?, path: Array<String, Integer>?}`
  # execute_field_lazy | `{ context: GraphQL::Query::Context::FieldResolutionContext?, owner: Class?, field: GraphQL::Schema::Field?, query: GraphqL::Query?, path: Array<String, Integer>?}`
  # 
  # Note that `execute_field` and `execute_field_lazy` receive different data in different settings:
  # 
  # - When using {GraphQL::Execution::Interpreter}, they receive `{field:, path:, query:}`
  # - Otherwise, they receive `{context: ...}`
  module Tracing
    # Install a tracer to receive events.
    # 
    # _@param_ `tracer` — 
    # 
    # _@deprecated_ — See {Schema#tracer} or use `context: { tracers: [...] }`
    sig { params(tracer: T::Array[T.untyped]).void }
    def self.install(tracer); end

    # 
    # _@deprecated_ — See {Schema#tracer} or use `context: { tracers: [...] }`
    sig { params(tracer: T.untyped).returns(T.untyped) }
    def self.uninstall(tracer); end

    # 
    # _@deprecated_ — See {Schema#tracer} or use `context: { tracers: [...] }`
    sig { returns(T.untyped) }
    def self.tracers; end

    # Objects may include traceable to gain a `.trace(...)` method.
    # The object must have a `@tracers` ivar of type `Array<<#trace(k, d, &b)>>`.
    # @api private
    module Traceable
      # _@param_ `key` — The name of the event in GraphQL internals
      # 
      # _@param_ `metadata` — Event-related metadata (can be anything)
      # 
      # _@return_ — Must return the value of the block
      sig { params(key: String, metadata: T::Hash[T.untyped, T.untyped]).returns(Object) }
      def trace(key, metadata); end

      # If there's a tracer at `idx`, call it and then increment `idx`.
      # Otherwise, yield.
      # 
      # _@param_ `idx` — Which tracer to call
      # 
      # _@param_ `key` — The current event name
      # 
      # _@param_ `metadata` — The current event object
      # 
      # _@return_ — Whatever the block returns
      sig { params(idx: Integer, key: String, metadata: Object).returns(T.untyped) }
      def call_tracers(idx, key, metadata); end
    end

    module NullTracer
      sig { params(k: T.untyped, v: T.untyped).returns(T.untyped) }
      def trace(k, v); end

      sig { params(k: T.untyped, v: T.untyped).returns(T.untyped) }
      def self.trace(k, v); end
    end

    class ScoutTracing < GraphQL::Tracing::PlatformTracing
      INSTRUMENT_OPTS = T.let({ scope: true }, T.untyped)

      sig { params(options: T.untyped).returns(ScoutTracing) }
      def initialize(options = {}); end

      sig { params(platform_key: T.untyped, key: T.untyped, data: T.untyped).returns(T.untyped) }
      def platform_trace(platform_key, key, data); end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def platform_field_key(type, field); end
    end

    class DataDogTracing < GraphQL::Tracing::PlatformTracing
      sig { params(platform_key: T.untyped, key: T.untyped, data: T.untyped).returns(T.untyped) }
      def platform_trace(platform_key, key, data); end

      sig { returns(T.untyped) }
      def service_name; end

      sig { returns(T.untyped) }
      def tracer; end

      sig { returns(T::Boolean) }
      def analytics_available?; end

      sig { returns(T::Boolean) }
      def analytics_enabled?; end

      sig { returns(T.untyped) }
      def analytics_sample_rate; end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def platform_field_key(type, field); end
    end

    # Each platform provides:
    # - `.platform_keys`
    # - `#platform_trace`
    # - `#platform_field_key(type, field)`
    # @api private
    class PlatformTracing
      sig { returns(T.untyped) }
      def self.platform_keys; end

      sig { params(value: T.untyped).returns(T.untyped) }
      def self.platform_keys=(value); end

      sig { params(options: T.untyped).returns(PlatformTracing) }
      def initialize(options = {}); end

      sig { params(key: T.untyped, data: T.untyped).returns(T.untyped) }
      def trace(key, data); end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def instrument(type, field); end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def trace_field(type, field); end

      sig { params(schema_defn: T.untyped, options: T.untyped).returns(T.untyped) }
      def self.use(schema_defn, options = {}); end

      sig { returns(T.untyped) }
      def options; end
    end

    class SkylightTracing < GraphQL::Tracing::PlatformTracing
      # _@param_ `set_endpoint_name` — If true, the GraphQL operation name will be used as the endpoint name. This is not advised if you run more than one query per HTTP request, for example, with `graphql-client` or multiplexing. It can also be specified per-query with `context[:set_skylight_endpoint_name]`.
      sig { params(options: T::Boolean).returns(SkylightTracing) }
      def initialize(options = {}); end

      sig { params(platform_key: T.untyped, key: T.untyped, data: T.untyped).returns(T.untyped) }
      def platform_trace(platform_key, key, data); end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def platform_field_key(type, field); end
    end

    class AppsignalTracing < GraphQL::Tracing::PlatformTracing
      sig { params(platform_key: T.untyped, key: T.untyped, data: T.untyped).returns(T.untyped) }
      def platform_trace(platform_key, key, data); end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def platform_field_key(type, field); end
    end

    class NewRelicTracing < GraphQL::Tracing::PlatformTracing
      # _@param_ `set_transaction_name` — If true, the GraphQL operation name will be used as the transaction name. This is not advised if you run more than one query per HTTP request, for example, with `graphql-client` or multiplexing. It can also be specified per-query with `context[:set_new_relic_transaction_name]`.
      sig { params(options: T::Boolean).returns(NewRelicTracing) }
      def initialize(options = {}); end

      sig { params(platform_key: T.untyped, key: T.untyped, data: T.untyped).returns(T.untyped) }
      def platform_trace(platform_key, key, data); end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def platform_field_key(type, field); end
    end

    class PrometheusTracing < GraphQL::Tracing::PlatformTracing
      DEFAULT_WHITELIST = T.let(['execute_field', 'execute_field_lazy'].freeze, T.untyped)
      DEFAULT_COLLECTOR_TYPE = T.let('graphql'.freeze, T.untyped)

      sig { params(opts: T.untyped).returns(PrometheusTracing) }
      def initialize(opts = {}); end

      sig do
        params(
          platform_key: T.untyped,
          key: T.untyped,
          data: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def platform_trace(platform_key, key, data, &block); end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def platform_field_key(type, field); end

      sig do
        params(
          platform_key: T.untyped,
          key: T.untyped,
          data: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def instrument_execution(platform_key, key, data, &block); end

      sig { params(platform_key: T.untyped, key: T.untyped, duration: T.untyped).returns(T.untyped) }
      def observe(platform_key, key, duration); end

      class GraphQLCollector < PrometheusExporter::Server::TypeCollector
        sig { returns(GraphQLCollector) }
        def initialize; end

        sig { returns(T.untyped) }
        def type; end

        sig { params(object: T.untyped).returns(T.untyped) }
        def collect(object); end

        sig { returns(T.untyped) }
        def metrics; end
      end
    end

    # This implementation forwards events to ActiveSupport::Notifications
    # with a `graphql.` prefix.
    module ActiveSupportNotificationsTracing
      KEYS = T.let({
  "lex" => "graphql.lex",
  "parse" => "graphql.parse",
  "validate" => "graphql.validate",
  "analyze_multiplex" => "graphql.analyze_multiplex",
  "analyze_query" => "graphql.analyze_query",
  "execute_query" => "graphql.execute_query",
  "execute_query_lazy" => "graphql.execute_query_lazy",
  "execute_field" => "graphql.execute_field",
  "execute_field_lazy" => "graphql.execute_field_lazy",
}, T.untyped)

      sig { params(key: T.untyped, metadata: T.untyped).returns(T.untyped) }
      def self.trace(key, metadata); end
    end
  end

  # Used for defined arguments ({Field}, {InputObjectType})
  # 
  # {#name} must be a String.
  # 
  # @example defining an argument for a field
  #   GraphQL::Field.define do
  #     # ...
  #     argument :favoriteFood, types.String, "Favorite thing to eat", default_value: "pizza"
  #   end
  # 
  # @example defining an argument for an {InputObjectType}
  #   GraphQL::InputObjectType.define do
  #     argument :newName, !types.String
  #   end
  # 
  # @example defining an argument with a `prepare` function
  #   GraphQL::Field.define do
  #     argument :userId, types.ID, prepare: ->(userId) do
  #       User.find_by(id: userId)
  #     end
  #   end
  # 
  # @example returning an {ExecutionError} from a `prepare` function
  #   GraphQL::Field.define do
  #     argument :date do
  #       type !types.String
  #       prepare ->(date) do
  #         return GraphQL::ExecutionError.new("Invalid date format") unless DateValidator.valid?(date)
  #         Time.zone.parse(date)
  #       end
  #     end
  #   end
  class Argument
    include GraphQL::Define::InstanceDefinable
    NO_DEFAULT_VALUE = T.let(Object.new, T.untyped)

    # Returns the value of attribute default_value
    sig { returns(T.untyped) }
    def default_value; end

    # Returns the value of attribute description
    sig { returns(T.untyped) }
    def description; end

    # Sets the attribute description
    # 
    # _@param_ `value` — the value to set the attribute description to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def description=(value); end

    # _@return_ — The name of this argument on its {GraphQL::Field} or {GraphQL::InputObjectType}
    sig { returns(String) }
    def name; end

    # _@return_ — The name of this argument on its {GraphQL::Field} or {GraphQL::InputObjectType}
    sig { params(value: String).returns(String) }
    def name=(value); end

    # Returns the value of attribute as
    sig { returns(T.untyped) }
    def as; end

    # Sets the attribute as
    # 
    # _@param_ `value` — the value to set the attribute as to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def as=(value); end

    # Returns the value of attribute ast_node
    sig { returns(T.untyped) }
    def ast_node; end

    # Sets the attribute ast_node
    # 
    # _@param_ `value` — the value to set the attribute ast_node to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def ast_node=(value); end

    # Returns the value of attribute method_access
    sig { returns(T.untyped) }
    def method_access; end

    # Sets the attribute method_access
    # 
    # _@param_ `value` — the value to set the attribute method_access to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def method_access=(value); end

    sig { returns(Argument) }
    def initialize; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    sig { returns(T::Boolean) }
    def default_value?; end

    sig { returns(T::Boolean) }
    def method_access?; end

    sig { params(new_default_value: T.untyped).returns(T.untyped) }
    def default_value=(new_default_value); end

    # _@param_ `new_input_type` — Assign a new input type for this argument (if it's a proc, it will be called after schema initialization)
    sig { params(new_input_type: T.any(GraphQL::BaseType, Proc)).returns(T.untyped) }
    def type=(new_input_type); end

    # _@return_ — the input type for this argument
    sig { returns(GraphQL::BaseType) }
    def type; end

    # _@return_ — The name of this argument inside `resolve` functions
    sig { returns(String) }
    def expose_as; end

    # Backport this to support legacy-style directives
    sig { returns(T.untyped) }
    def keyword; end

    # _@param_ `value` — The incoming value from variables or query string literal
    # 
    # _@param_ `ctx` — 
    # 
    # _@return_ — The prepared `value` for this argument or `value` itself if no `prepare` function exists.
    sig { params(value: Object, ctx: GraphQL::Query::Context).returns(Object) }
    def prepare(value, ctx); end

    # Assign a `prepare` function to prepare this argument's value before `resolve` functions are called.
    # 
    # _@param_ `prepare_proc` — ]
    sig { params(prepare_proc: T.untyped).returns(T.untyped) }
    def prepare=(prepare_proc); end

    sig { returns(T.untyped) }
    def type_class; end

    sig do
      params(
        name: T.untyped,
        type_or_argument: T.untyped,
        description: T.untyped,
        as: T.untyped,
        default_value: T.untyped,
        prepare: T.untyped,
        kwargs: T.untyped,
        block: T.untyped
      ).returns(T.untyped)
    end
    def self.from_dsl(name, type_or_argument = nil, description = nil, as: nil, default_value: NO_DEFAULT_VALUE, prepare: DefaultPrepare, **kwargs, &block); end

    sig { params(val: T.untyped).returns(T.untyped) }
    def self.deep_stringify(val); end

    # `metadata` can store arbitrary key-values with an object.
    # 
    # _@return_ — Hash for user-defined storage
    sig { returns(T::Hash[Object, Object]) }
    def metadata; end

    # Mutate this instance using functions from its {.definition}s.
    # Keywords or helpers in the block correspond to keys given to `accepts_definitions`.
    # 
    # Note that the block is not called right away -- instead, it's deferred until
    # one of the defined fields is needed.
    sig { params(kwargs: T.untyped, block: T.untyped).void }
    def define(**kwargs, &block); end

    # Shallow-copy this object, then apply new definitions to the copy.
    # 
    # _@return_ — A new instance, with any extended definitions
    # 
    # _@see_ `{#define}` — for arguments
    sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::Define::InstanceDefinable) }
    def redefine(**kwargs, &block); end

    # Run the definition block if it hasn't been run yet.
    # This can only be run once: the block is deleted after it's used.
    # You have to call this before using any value which could
    # come from the definition block.
    sig { void }
    def ensure_defined; end

    # Take the pending methods and put them back on this object's singleton class.
    # This reverts the process done by {#stash_dependent_methods}
    sig { void }
    def revive_dependent_methods; end

    # Find the method names which were declared as definition-dependent,
    # then grab the method definitions off of this object's class
    # and store them for later.
    # 
    # Then make a dummy method for each of those method names which:
    # 
    # - Triggers the pending definition, if there is one
    # - Calls the same method again.
    # 
    # It's assumed that {#ensure_defined} will put the original method definitions
    # back in place with {#revive_dependent_methods}.
    sig { void }
    def stash_dependent_methods; end

    # @api private
    module DefaultPrepare
      sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.call(value, ctx); end
    end
  end

  # A reusable container for field logic, including arguments, resolve, return type, and documentation.
  # 
  # Class-level values defined with the DSL will be inherited,
  # so {GraphQL::Function}s can extend one another.
  # 
  # It's OK to override the instance methods here in order to customize behavior of instances.
  # 
  # @example A reusable GraphQL::Function attached as a field
  #   class FindRecord < GraphQL::Function
  #     attr_reader :type
  # 
  #     def initialize(model:, type:)
  #       @model = model
  #       @type = type
  #     end
  # 
  #     argument :id, GraphQL::ID_TYPE
  # 
  #     def call(obj, args, ctx)
  #        @model.find(args.id)
  #     end
  #   end
  # 
  #   QueryType = GraphQL::ObjectType.define do
  #     name "Query"
  #     field :post, function: FindRecord.new(model: Post, type: PostType)
  #     field :comment, function: FindRecord.new(model: Comment, type: CommentType)
  #   end
  # 
  # @see {GraphQL::Schema::Resolver} for a replacement for `GraphQL::Function`
  class Function
    # _@return_ — Arguments, keyed by name
    sig { returns(T::Hash[String, GraphQL::Argument]) }
    def arguments; end

    # _@return_ — Return type
    sig { returns(GraphQL::BaseType) }
    def type; end

    # _@return_ — This function's resolver
    sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(Object) }
    def call(obj, args, ctx); end

    sig { returns(T.nilable(String)) }
    def description; end

    sig { returns(T.nilable(String)) }
    def deprecation_reason; end

    sig { returns(T.any(Integer, Proc)) }
    def complexity; end

    # Define an argument for this function & its subclasses
    # 
    # _@see_ `{GraphQL::Field}` — same arguments as the `argument` definition helper
    sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).void }
    def self.argument(*args, **kwargs, &block); end

    # _@return_ — Arguments for this function class, including inherited arguments
    sig { returns(T::Hash[String, GraphQL::Argument]) }
    def self.arguments; end

    # Provides shorthand access to GraphQL's built-in types
    sig { returns(T.untyped) }
    def self.types; end

    # Get or set the return type for this function class & descendants
    sig { params(premade_type: T.untyped, block: T.untyped).returns(GraphQL::BaseType) }
    def self.type(premade_type = nil, &block); end

    sig { params(function: T.untyped).returns(T.untyped) }
    def self.build_field(function); end

    # Class-level reader/writer which is inherited
    sig { params(name: T.untyped).returns(T.untyped) }
    def self.inherited_value(name); end

    # Get or set this class's description
    sig { params(new_value: T.untyped).returns(T.untyped) }
    def self.description(new_value = nil); end

    # Get or set this class's deprecation_reason
    sig { params(new_value: T.untyped).returns(T.untyped) }
    def self.deprecation_reason(new_value = nil); end

    # Get or set this class's complexity
    sig { params(new_value: T.untyped).returns(T.untyped) }
    def self.complexity(new_value = nil); end

    # Does this function inherit from another function?
    sig { returns(T::Boolean) }
    def self.parent_function?; end

    # Arguments defined on this class (not superclasses)
    sig { returns(T.untyped) }
    def self.own_arguments; end
  end

  module Language
    sig { params(value: T.untyped).returns(T.untyped) }
    def self.serialize(value); end

    module Lexer
      ESCAPES = T.let(/\\["\\\/bfnrt]/, T.untyped)
      ESCAPES_REPLACE = T.let({
'\\"' => '"',
"\\\\" => "\\",
"\\/" => '/',
"\\b" => "\b",
"\\f" => "\f",
"\\n" => "\n",
"\\r" => "\r",
"\\t" => "\t",
}, T.untyped)
      UTF_8 = T.let(/\\u[\dAa-f]{4}/i, T.untyped)
      UTF_8_REPLACE = T.let(->(m) { [m[-4..-1].to_i(16)].pack('U'.freeze) }, T.untyped)
      VALID_STRING = T.let(/\A(?:[^\\]|#{ESCAPES}|#{UTF_8})*\z/o, T.untyped)
      PACK_DIRECTIVE = T.let("c*", T.untyped)
      UTF_8_ENCODING = T.let("UTF-8", T.untyped)

      sig { params(query_string: T.untyped).returns(T.untyped) }
      def self.tokenize(query_string); end

      # Replace any escaped unicode or whitespace with the _actual_ characters
      # To avoid allocating more strings, this modifies the string passed into it
      sig { params(raw_string: T.untyped).returns(T.untyped) }
      def self.replace_escaped_characters_in_place(raw_string); end

      # Returns the value of attribute _graphql_lexer_trans_keys
      sig { returns(T.untyped) }
      def self._graphql_lexer_trans_keys; end

      # Sets the attribute _graphql_lexer_trans_keys
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_trans_keys to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_trans_keys=(value); end

      # Returns the value of attribute _graphql_lexer_char_class
      sig { returns(T.untyped) }
      def self._graphql_lexer_char_class; end

      # Sets the attribute _graphql_lexer_char_class
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_char_class to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_char_class=(value); end

      # Returns the value of attribute _graphql_lexer_index_offsets
      sig { returns(T.untyped) }
      def self._graphql_lexer_index_offsets; end

      # Sets the attribute _graphql_lexer_index_offsets
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_index_offsets to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_index_offsets=(value); end

      # Returns the value of attribute _graphql_lexer_indicies
      sig { returns(T.untyped) }
      def self._graphql_lexer_indicies; end

      # Sets the attribute _graphql_lexer_indicies
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_indicies to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_indicies=(value); end

      # Returns the value of attribute _graphql_lexer_index_defaults
      sig { returns(T.untyped) }
      def self._graphql_lexer_index_defaults; end

      # Sets the attribute _graphql_lexer_index_defaults
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_index_defaults to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_index_defaults=(value); end

      # Returns the value of attribute _graphql_lexer_trans_cond_spaces
      sig { returns(T.untyped) }
      def self._graphql_lexer_trans_cond_spaces; end

      # Sets the attribute _graphql_lexer_trans_cond_spaces
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_trans_cond_spaces to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_trans_cond_spaces=(value); end

      # Returns the value of attribute _graphql_lexer_cond_targs
      sig { returns(T.untyped) }
      def self._graphql_lexer_cond_targs; end

      # Sets the attribute _graphql_lexer_cond_targs
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_cond_targs to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_cond_targs=(value); end

      # Returns the value of attribute _graphql_lexer_cond_actions
      sig { returns(T.untyped) }
      def self._graphql_lexer_cond_actions; end

      # Sets the attribute _graphql_lexer_cond_actions
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_cond_actions to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_cond_actions=(value); end

      # Returns the value of attribute _graphql_lexer_to_state_actions
      sig { returns(T.untyped) }
      def self._graphql_lexer_to_state_actions; end

      # Sets the attribute _graphql_lexer_to_state_actions
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_to_state_actions to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_to_state_actions=(value); end

      # Returns the value of attribute _graphql_lexer_from_state_actions
      sig { returns(T.untyped) }
      def self._graphql_lexer_from_state_actions; end

      # Sets the attribute _graphql_lexer_from_state_actions
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_from_state_actions to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_from_state_actions=(value); end

      # Returns the value of attribute _graphql_lexer_eof_trans
      sig { returns(T.untyped) }
      def self._graphql_lexer_eof_trans; end

      # Sets the attribute _graphql_lexer_eof_trans
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_eof_trans to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_eof_trans=(value); end

      # Returns the value of attribute _graphql_lexer_nfa_targs
      sig { returns(T.untyped) }
      def self._graphql_lexer_nfa_targs; end

      # Sets the attribute _graphql_lexer_nfa_targs
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_nfa_targs to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_nfa_targs=(value); end

      # Returns the value of attribute _graphql_lexer_nfa_offsets
      sig { returns(T.untyped) }
      def self._graphql_lexer_nfa_offsets; end

      # Sets the attribute _graphql_lexer_nfa_offsets
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_nfa_offsets to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_nfa_offsets=(value); end

      # Returns the value of attribute _graphql_lexer_nfa_push_actions
      sig { returns(T.untyped) }
      def self._graphql_lexer_nfa_push_actions; end

      # Sets the attribute _graphql_lexer_nfa_push_actions
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_nfa_push_actions to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_nfa_push_actions=(value); end

      # Returns the value of attribute _graphql_lexer_nfa_pop_trans
      sig { returns(T.untyped) }
      def self._graphql_lexer_nfa_pop_trans; end

      # Sets the attribute _graphql_lexer_nfa_pop_trans
      # 
      # _@param_ `value` — the value to set the attribute _graphql_lexer_nfa_pop_trans to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self._graphql_lexer_nfa_pop_trans=(value); end

      # Returns the value of attribute graphql_lexer_start
      sig { returns(T.untyped) }
      def self.graphql_lexer_start; end

      # Sets the attribute graphql_lexer_start
      # 
      # _@param_ `value` — the value to set the attribute graphql_lexer_start to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self.graphql_lexer_start=(value); end

      # Returns the value of attribute graphql_lexer_first_final
      sig { returns(T.untyped) }
      def self.graphql_lexer_first_final; end

      # Sets the attribute graphql_lexer_first_final
      # 
      # _@param_ `value` — the value to set the attribute graphql_lexer_first_final to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self.graphql_lexer_first_final=(value); end

      # Returns the value of attribute graphql_lexer_error
      sig { returns(T.untyped) }
      def self.graphql_lexer_error; end

      # Sets the attribute graphql_lexer_error
      # 
      # _@param_ `value` — the value to set the attribute graphql_lexer_error to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self.graphql_lexer_error=(value); end

      # Returns the value of attribute graphql_lexer_en_str
      sig { returns(T.untyped) }
      def self.graphql_lexer_en_str; end

      # Sets the attribute graphql_lexer_en_str
      # 
      # _@param_ `value` — the value to set the attribute graphql_lexer_en_str to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self.graphql_lexer_en_str=(value); end

      # Returns the value of attribute graphql_lexer_en_main
      sig { returns(T.untyped) }
      def self.graphql_lexer_en_main; end

      # Sets the attribute graphql_lexer_en_main
      # 
      # _@param_ `value` — the value to set the attribute graphql_lexer_en_main to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def self.graphql_lexer_en_main=(value); end

      sig { params(query_string: T.untyped).returns(T.untyped) }
      def self.run_lexer(query_string); end

      sig { params(ts: T.untyped, te: T.untyped, meta: T.untyped).returns(T.untyped) }
      def self.record_comment(ts, te, meta); end

      sig do
        params(
          token_name: T.untyped,
          ts: T.untyped,
          te: T.untyped,
          meta: T.untyped
        ).returns(T.untyped)
      end
      def self.emit(token_name, ts, te, meta); end

      sig do
        params(
          ts: T.untyped,
          te: T.untyped,
          meta: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def self.emit_string(ts, te, meta, block:); end
    end

    module Nodes
      # _@return_ — The identifier for this variable, _without_ `$`
      sig { returns(String) }
      def name; end

      # _@return_ — The identifier for this variable, _without_ `$`
      sig { params(value: String).returns(String) }
      def name=(value); end

      # _@return_ — The expected type of this value
      sig { returns(T.any(TypeName, T.untyped)) }
      def type; end

      # _@return_ — The expected type of this value
      sig { params(value: T.any(TypeName, T.untyped)).returns(T.any(TypeName, T.untyped)) }
      def type=(value); end

      # _@return_ — A Ruby value to use if no other value is provided
      sig { returns(T.any(String, Integer, Float, T::Boolean, T::Array[T.untyped], NullValue)) }
      def default_value; end

      # _@return_ — A Ruby value to use if no other value is provided
      sig { params(value: T.any(String, Integer, Float, T::Boolean, T::Array[T.untyped], NullValue)).returns(T.any(String, Integer, Float, T::Boolean, T::Array[T.untyped], NullValue)) }
      def default_value=(value); end

      # {AbstractNode} is the base class for all nodes in a GraphQL AST.
      # 
      # It provides some APIs for working with ASTs:
      # - `children` returns all AST nodes attached to this one. Used for tree traversal.
      # - `scalars` returns all scalar (Ruby) values attached to this one. Used for comparing nodes.
      # - `to_query_string` turns an AST node into a GraphQL string
      class AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute line
        sig { returns(T.untyped) }
        def line; end

        # Returns the value of attribute col
        sig { returns(T.untyped) }
        def col; end

        # Returns the value of attribute filename
        sig { returns(T.untyped) }
        def filename; end

        # Initialize a node by extracting its position,
        # then calling the class's `initialize_node` method.
        # 
        # _@param_ `options` — Initial attributes for this node
        sig { params(options: T::Hash[T.untyped, T.untyped]).returns(AbstractNode) }
        def initialize(options = {}); end

        # Value equality
        # 
        # _@return_ — True if `self` is equivalent to `other`
        sig { params(other: T.untyped).returns(T::Boolean) }
        def eql?(other); end

        # _@return_ — all nodes in the tree below this one
        sig { returns(T::Array[GraphQL::Language::Nodes::AbstractNode]) }
        def children; end

        # _@return_ — Scalar values attached to this node
        sig { returns(T::Array[T.any(Integer, Float, String, T::Boolean, T::Array[T.untyped])]) }
        def scalars; end

        # This might be unnecessary, but its easiest to add it here.
        sig { params(other: T.untyped).returns(T.untyped) }
        def initialize_copy(other); end

        # _@return_ — the method to call on {Language::Visitor} for this node
        sig { returns(Symbol) }
        def visit_method; end

        sig { returns(T.untyped) }
        def position; end

        sig { params(printer: T.untyped).returns(T.untyped) }
        def to_query_string(printer: GraphQL::Language::Printer.new); end

        # This creates a copy of `self`, with `new_options` applied.
        # 
        # _@param_ `new_options` — 
        # 
        # _@return_ — a shallow copy of `self`
        sig { params(new_options: T::Hash[T.untyped, T.untyped]).returns(AbstractNode) }
        def merge(new_options); end

        # Copy `self`, but modify the copy so that `previous_child` is replaced by `new_child`
        sig { params(previous_child: T.untyped, new_child: T.untyped).returns(T.untyped) }
        def replace_child(previous_child, new_child); end

        # TODO DRY with `replace_child`
        sig { params(previous_child: T.untyped).returns(T.untyped) }
        def delete_child(previous_child); end

        sig { params(new_options: T.untyped).returns(T.untyped) }
        def merge!(new_options); end

        # Add a default `#visit_method` and `#children_method_name` using the class name
        sig { params(child_class: T.untyped).returns(T.untyped) }
        def self.inherited(child_class); end

        # Name accessors which return lists of nodes,
        # along with the kind of node they return, if possible.
        # - Add a reader for these children
        # - Add a persistent update method to add a child
        # - Generate a `#children` method
        sig { params(children_of_type: T.untyped).returns(T.untyped) }
        def self.children_methods(children_of_type); end

        # These methods return a plain Ruby value, not another node
        # - Add reader methods
        # - Add a `#scalars` method
        sig { params(method_names: T.untyped).returns(T.untyped) }
        def self.scalar_methods(*method_names); end

        sig { returns(T.untyped) }
        def self.generate_initialize_node; end

        module DefinitionNode
          # This AST node's {#line} returns the first line, which may be the description.
          # 
          # _@return_ — The first line of the definition (not the description)
          sig { returns(Integer) }
          def definition_line; end

          sig { params(options: T.untyped).returns(T.untyped) }
          def initialize(options = {}); end
        end
      end

      # Base class for non-null type names and list type names
      class WrapperType < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      # Base class for nodes whose only value is a name (no child nodes or other scalars)
      class NameOnlyNode < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      # A key-value pair for a field's inputs
      class Argument < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # _@return_ — the key for this argument
        sig { returns(String) }
        def name; end

        # _@return_ — the key for this argument
        sig { params(value: String).returns(String) }
        def name=(value); end

        sig { returns(T.untyped) }
        def children; end

        # _@return_ — The value passed for this key
        sig { returns(T.any(String, Float, Integer, T::Boolean, T::Array[T.untyped], InputObject)) }
        def value; end

        # _@return_ — The value passed for this key
        sig { params(value: T.any(String, Float, Integer, T::Boolean, T::Array[T.untyped], InputObject)).returns(T.any(String, Float, Integer, T::Boolean, T::Array[T.untyped], InputObject)) }
        def value=(value); end
      end

      class Directive < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      class DirectiveLocation < GraphQL::Language::Nodes::NameOnlyNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      class DirectiveDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end
      end

      # This is the AST root for normal queries
      # 
      # @example Deriving a document by parsing a string
      #   document = GraphQL.parse(query_string)
      # 
      # @example Creating a string from a document
      #   document.to_query_string
      #   # { ... }
      # 
      # @example Creating a custom string from a document
      #  class VariableScrubber < GraphQL::Language::Printer
      #    def print_argument(arg)
      #      "#{arg.name}: <HIDDEN>"
      #    end
      #  end
      # 
      #  document.to_query_string(printer: VariableSrubber.new)
      class Document < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { params(name: T.untyped).returns(T.untyped) }
        def slice_definition(name); end

        # _@return_ — top-level GraphQL units: operations or fragments
        sig { returns(T::Array[T.any(OperationDefinition, FragmentDefinition)]) }
        def definitions; end

        # _@return_ — top-level GraphQL units: operations or fragments
        sig { params(value: T::Array[T.any(OperationDefinition, FragmentDefinition)]).returns(T::Array[T.any(OperationDefinition, FragmentDefinition)]) }
        def definitions=(value); end
      end

      # An enum value. The string is available as {#name}.
      class Enum < GraphQL::Language::Nodes::NameOnlyNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      # A null value literal.
      class NullValue < GraphQL::Language::Nodes::NameOnlyNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      # A single selection in a GraphQL query.
      class Field < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig do
          params(
            name: T.untyped,
            arguments: T.untyped,
            directives: T.untyped,
            selections: T.untyped,
            kwargs: T.untyped
          ).returns(T.untyped)
        end
        def initialize_node(name: nil, arguments: [], directives: [], selections: [], **kwargs); end

        # _@return_ — Selections on this object (or empty array if this is a scalar field)
        sig { returns(T::Array[Nodes::Field]) }
        def selections; end

        # _@return_ — Selections on this object (or empty array if this is a scalar field)
        sig { params(value: T::Array[Nodes::Field]).returns(T::Array[Nodes::Field]) }
        def selections=(value); end

        # Override this because default is `:fields`
        sig { returns(T.untyped) }
        def children_method_name; end
      end

      # A reusable fragment, defined at document-level.
      class FragmentDefinition < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # _@return_ — the identifier for this fragment, which may be applied with `...#{name}`
        sig { returns(String) }
        def name; end

        # _@return_ — the identifier for this fragment, which may be applied with `...#{name}`
        sig { params(value: String).returns(String) }
        def name=(value); end

        sig do
          params(
            name: T.untyped,
            type: T.untyped,
            directives: T.untyped,
            selections: T.untyped
          ).returns(T.untyped)
        end
        def initialize_node(name: nil, type: nil, directives: [], selections: []); end

        # _@return_ — the type condition for this fragment (name of type which it may apply to)
        sig { returns(String) }
        def type; end

        # _@return_ — the type condition for this fragment (name of type which it may apply to)
        sig { params(value: String).returns(String) }
        def type=(value); end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      # Application of a named fragment in a selection
      class FragmentSpread < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      # An unnamed fragment, defined directly in the query with `... {  }`
      class InlineFragment < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      # A collection of key-value inputs which may be a field argument
      class InputObject < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # _@return_ — A list of key-value pairs inside this input object
        sig { returns(T::Array[Nodes::Argument]) }
        def arguments; end

        # _@return_ — A list of key-value pairs inside this input object
        sig { params(value: T::Array[Nodes::Argument]).returns(T::Array[Nodes::Argument]) }
        def arguments=(value); end

        # _@return_ — Recursively turn this input object into a Ruby Hash
        sig { params(options: T.untyped).returns(T::Hash[String, T.untyped]) }
        def to_h(options = {}); end

        sig { returns(T.untyped) }
        def children_method_name; end

        sig { params(value: T.untyped).returns(T.untyped) }
        def serialize_value_for_hash(value); end
      end

      # A list type definition, denoted with `[...]` (used for variable type definitions)
      class ListType < GraphQL::Language::Nodes::WrapperType
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      # A non-null type definition, denoted with `...!` (used for variable type definitions)
      class NonNullType < GraphQL::Language::Nodes::WrapperType
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      # An operation-level query variable
      class VariableDefinition < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      # A query, mutation or subscription.
      # May be anonymous or named.
      # May be explicitly typed (eg `mutation { ... }`) or implicitly a query (eg `{ ... }`).
      class OperationDefinition < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # _@return_ — Variable $definitions for this operation
        sig { returns(T::Array[VariableDefinition]) }
        def variables; end

        # _@return_ — Variable $definitions for this operation
        sig { params(value: T::Array[VariableDefinition]).returns(T::Array[VariableDefinition]) }
        def variables=(value); end

        # _@return_ — Root-level fields on this operation
        sig { returns(T::Array[T.untyped]) }
        def selections; end

        # _@return_ — Root-level fields on this operation
        sig { params(value: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
        def selections=(value); end

        # _@return_ — The root type for this operation, or `nil` for implicit `"query"`
        sig { returns(T.nilable(String)) }
        def operation_type; end

        # _@return_ — The root type for this operation, or `nil` for implicit `"query"`
        sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
        def operation_type=(value); end

        sig { returns(T.untyped) }
        def children_method_name; end

        # _@return_ — The name for this operation, or `nil` if unnamed
        sig { returns(T.nilable(String)) }
        def name; end

        # _@return_ — The name for this operation, or `nil` if unnamed
        sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
        def name=(value); end
      end

      # A type name, used for variable definitions
      class TypeName < GraphQL::Language::Nodes::NameOnlyNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      # Usage of a variable in a query. Name does _not_ include `$`.
      class VariableIdentifier < GraphQL::Language::Nodes::NameOnlyNode
        NO_CHILDREN = T.let([].freeze, T.untyped)
      end

      class SchemaDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class SchemaExtension < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class ScalarTypeDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class ScalarTypeExtension < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class InputValueDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class FieldDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        sig { returns(T.untyped) }
        def children_method_name; end

        sig { params(new_options: T.untyped).returns(T.untyped) }
        def merge(new_options); end
      end

      class ObjectTypeDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class ObjectTypeExtension < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class InterfaceTypeDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class InterfaceTypeExtension < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class UnionTypeDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        # Returns the value of attribute types
        sig { returns(T.untyped) }
        def types; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class UnionTypeExtension < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute types
        sig { returns(T.untyped) }
        def types; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class EnumValueDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class EnumTypeDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class EnumTypeExtension < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class InputObjectTypeDefinition < GraphQL::Language::Nodes::AbstractNode
        include DefinitionNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        # Returns the value of attribute description
        sig { returns(T.untyped) }
        def description; end

        sig { returns(T.untyped) }
        def children_method_name; end
      end

      class InputObjectTypeExtension < GraphQL::Language::Nodes::AbstractNode
        NO_CHILDREN = T.let([].freeze, T.untyped)

        sig { returns(T.untyped) }
        def children_method_name; end
      end
    end

    # Emitted by the lexer and passed to the parser.
    # Contains type, value and position data.
    class Token
      # _@return_ — The kind of token this is
      sig { returns(Symbol) }
      def name; end

      # _@return_ — The text of this token
      sig { returns(String) }
      def value; end

      # Returns the value of attribute prev_token
      sig { returns(T.untyped) }
      def prev_token; end

      # Returns the value of attribute line
      sig { returns(T.untyped) }
      def line; end

      # Returns the value of attribute col
      sig { returns(T.untyped) }
      def col; end

      sig do
        params(
          value: T.untyped,
          name: T.untyped,
          line: T.untyped,
          col: T.untyped,
          prev_token: T.untyped
        ).returns(Token)
      end
      def initialize(value:, name:, line:, col:, prev_token:); end

      sig { returns(T.untyped) }
      def to_i; end

      sig { returns(T.untyped) }
      def to_f; end

      sig { returns(T.untyped) }
      def line_and_column; end

      sig { returns(T.untyped) }
      def inspect; end
    end

    class Parser < Racc::Parser
      Racc_arg = T.let([
racc_action_table,
racc_action_check,
racc_action_default,
racc_action_pointer,
racc_goto_table,
racc_goto_check,
racc_goto_default,
racc_goto_pointer,
racc_nt_base,
racc_reduce_table,
racc_token_table,
racc_shift_n,
racc_reduce_n,
racc_use_result_var ], T.untyped)
      Racc_token_to_s_table = T.let([
"$end",
"error",
"LCURLY",
"RCURLY",
"QUERY",
"MUTATION",
"SUBSCRIPTION",
"LPAREN",
"RPAREN",
"VAR_SIGN",
"COLON",
"BANG",
"LBRACKET",
"RBRACKET",
"EQUALS",
"ON",
"SCHEMA",
"SCALAR",
"TYPE",
"IMPLEMENTS",
"INTERFACE",
"UNION",
"ENUM",
"INPUT",
"DIRECTIVE",
"IDENTIFIER",
"FRAGMENT",
"TRUE",
"FALSE",
"FLOAT",
"INT",
"STRING",
"NULL",
"DIR_SIGN",
"ELLIPSIS",
"EXTEND",
"AMP",
"PIPE",
"$start",
"target",
"document",
"definitions_list",
"definition",
"executable_definition",
"type_system_definition",
"type_system_extension",
"operation_definition",
"fragment_definition",
"operation_type",
"operation_name_opt",
"variable_definitions_opt",
"directives_list_opt",
"selection_set",
"selection_list",
"name",
"variable_definitions_list",
"variable_definition",
"type",
"default_value_opt",
"nullable_type",
"literal_value",
"selection_set_opt",
"selection",
"field",
"fragment_spread",
"inline_fragment",
"arguments_opt",
"name_without_on",
"schema_keyword",
"enum_name",
"enum_value_definition",
"description_opt",
"enum_value_definitions",
"arguments_list",
"argument",
"input_value",
"null_value",
"enum_value",
"list_value",
"object_literal_value",
"variable",
"object_value",
"list_value_list",
"object_value_list",
"object_value_field",
"object_literal_value_list",
"object_literal_value_field",
"directives_list",
"directive",
"fragment_name_opt",
"schema_definition",
"type_definition",
"directive_definition",
"operation_type_definition_list",
"operation_type_definition",
"scalar_type_definition",
"object_type_definition",
"interface_type_definition",
"union_type_definition",
"enum_type_definition",
"input_object_type_definition",
"schema_extension",
"type_extension",
"scalar_type_extension",
"object_type_extension",
"interface_type_extension",
"union_type_extension",
"enum_type_extension",
"input_object_type_extension",
"implements",
"field_definition_list",
"implements_opt",
"union_members",
"input_value_definition_list",
"description",
"interfaces_list",
"legacy_interfaces_list",
"input_value_definition",
"arguments_definitions_opt",
"field_definition",
"directive_locations" ], T.untyped)
      Racc_debug_parser = T.let(false, T.untyped)

      sig { params(val: T.untyped, _values: T.untyped, result: T.untyped).returns(T.untyped) }
      def _reduce_none(val, _values, result); end
    end

    class Printer
      # Turn an arbitrary AST node back into a string.
      # 
      # _@param_ `indent` — Whitespace to add to the printed node
      # 
      # _@return_ — Valid GraphQL for `node`
      # 
      # Turning a document into a query string
      # ```ruby
      # document = GraphQL.parse(query_string)
      # GraphQL::Language::Printer.new.print(document)
      # # => "{ ... }"
      # ```
      # 
      # Building a custom printer
      # ```ruby
      # 
      # class MyPrinter < GraphQL::Language::Printer
      #   def print_argument(arg)
      #     "#{arg.name}: <HIDDEN>"
      #   end
      # end
      # 
      # MyPrinter.new.print(document)
      # # => "mutation { pay(creditCard: <HIDDEN>) { success } }"
      # ```
      sig { params(node: T.untyped, indent: String).returns(String) }
      def print(node, indent: ""); end

      sig { params(document: T.untyped).returns(T.untyped) }
      def print_document(document); end

      sig { params(argument: T.untyped).returns(T.untyped) }
      def print_argument(argument); end

      sig { params(directive: T.untyped).returns(T.untyped) }
      def print_directive(directive); end

      sig { params(enum: T.untyped).returns(T.untyped) }
      def print_enum(enum); end

      sig { returns(T.untyped) }
      def print_null_value; end

      sig { params(field: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_field(field, indent: ""); end

      sig { params(fragment_def: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_fragment_definition(fragment_def, indent: ""); end

      sig { params(fragment_spread: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_fragment_spread(fragment_spread, indent: ""); end

      sig { params(inline_fragment: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_inline_fragment(inline_fragment, indent: ""); end

      sig { params(input_object: T.untyped).returns(T.untyped) }
      def print_input_object(input_object); end

      sig { params(list_type: T.untyped).returns(T.untyped) }
      def print_list_type(list_type); end

      sig { params(non_null_type: T.untyped).returns(T.untyped) }
      def print_non_null_type(non_null_type); end

      sig { params(operation_definition: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_operation_definition(operation_definition, indent: ""); end

      sig { params(type_name: T.untyped).returns(T.untyped) }
      def print_type_name(type_name); end

      sig { params(variable_definition: T.untyped).returns(T.untyped) }
      def print_variable_definition(variable_definition); end

      sig { params(variable_identifier: T.untyped).returns(T.untyped) }
      def print_variable_identifier(variable_identifier); end

      sig { params(schema: T.untyped).returns(T.untyped) }
      def print_schema_definition(schema); end

      sig { params(scalar_type: T.untyped).returns(T.untyped) }
      def print_scalar_type_definition(scalar_type); end

      sig { params(object_type: T.untyped).returns(T.untyped) }
      def print_object_type_definition(object_type); end

      sig { params(input_value: T.untyped).returns(T.untyped) }
      def print_input_value_definition(input_value); end

      sig { params(arguments: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_arguments(arguments, indent: ""); end

      sig { params(field: T.untyped).returns(T.untyped) }
      def print_field_definition(field); end

      sig { params(interface_type: T.untyped).returns(T.untyped) }
      def print_interface_type_definition(interface_type); end

      sig { params(union_type: T.untyped).returns(T.untyped) }
      def print_union_type_definition(union_type); end

      sig { params(enum_type: T.untyped).returns(T.untyped) }
      def print_enum_type_definition(enum_type); end

      sig { params(enum_value: T.untyped).returns(T.untyped) }
      def print_enum_value_definition(enum_value); end

      sig { params(input_object_type: T.untyped).returns(T.untyped) }
      def print_input_object_type_definition(input_object_type); end

      sig { params(directive: T.untyped).returns(T.untyped) }
      def print_directive_definition(directive); end

      sig { params(node: T.untyped, indent: T.untyped, first_in_block: T.untyped).returns(T.untyped) }
      def print_description(node, indent: "", first_in_block: true); end

      sig { params(fields: T.untyped).returns(T.untyped) }
      def print_field_definitions(fields); end

      sig { params(directives: T.untyped).returns(T.untyped) }
      def print_directives(directives); end

      sig { params(selections: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_selections(selections, indent: ""); end

      sig { params(node: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_node(node, indent: ""); end

      # Returns the value of attribute node
      sig { returns(T.untyped) }
      def node; end
    end

    # Depth-first traversal through the tree, calling hooks at each stop.
    # 
    # @example Create a visitor counting certain field names
    #   class NameCounter < GraphQL::Language::Visitor
    #     def initialize(document, field_name)
    #       super(document)
    #       @field_name = field_name
    #       @count = 0
    #     end
    # 
    #     attr_reader :count
    # 
    #     def on_field(node, parent)
    #       # if this field matches our search, increment the counter
    #       if node.name == @field_name
    #         @count += 1
    #       end
    #       # Continue visiting subfields:
    #       super
    #     end
    #   end
    # 
    #   # Initialize a visitor
    #   visitor = NameCounter.new(document, "name")
    #   # Run it
    #   visitor.visit
    #   # Check the result
    #   visitor.count
    #   # => 3
    class Visitor
      SKIP = T.let(:_skip, T.untyped)
      DELETE_NODE = T.let(DeleteNode.new, T.untyped)

      sig { params(document: T.untyped).returns(Visitor) }
      def initialize(document); end

      # _@return_ — The document with any modifications applied
      sig { returns(GraphQL::Language::Nodes::Document) }
      def result; end

      # Get a {NodeVisitor} for `node_class`
      # 
      # _@param_ `node_class` — The node class that you want to listen to
      # 
      # Run a hook whenever you enter a new Field
      # ```ruby
      # visitor[GraphQL::Language::Nodes::Field] << ->(node, parent) { p "Here's a field" }
      # ```
      # 
      # _@deprecated_ — see `on_` methods, like {#on_field}
      sig { params(node_class: Class).returns(NodeVisitor) }
      def [](node_class); end

      # Visit `document` and all children, applying hooks as you go
      sig { void }
      def visit; end

      # Call the user-defined handler for `node`.
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def visit_node(node, parent); end

      # The default implementation for visiting an AST node.
      # It doesn't _do_ anything, but it continues to visiting the node's children.
      # To customize this hook, override one of its make_visit_methodes (or the base method?)
      # in your subclasses.
      # 
      # For compatibility, it calls hook procs, too.
      # 
      # _@param_ `node` — the node being visited
      # 
      # _@param_ `parent` — the previously-visited node, or `nil` if this is the root node.
      # 
      # _@return_ — If there were modifications, it returns an array of new nodes, otherwise, it returns `nil`.
      sig { params(node: GraphQL::Language::Nodes::AbstractNode, parent: T.nilable(GraphQL::Language::Nodes::AbstractNode)).returns(T.nilable(T::Array[T.untyped])) }
      def on_abstract_node(node, parent); end

      # We don't use `alias` here because it breaks `super`
      sig { params(node_method: T.untyped).returns(T.untyped) }
      def self.make_visit_method(node_method); end

      # Run the hooks for `node`, and if the hooks return a copy of `node`,
      # copy `parent` so that it contains the copy of that node as a child,
      # then return the copies
      # If a non-array value is returned, consuming functions should ignore
      # said value
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_node_with_modifications(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def begin_visit(node, parent); end

      # Should global `leave` visitors come first or last?
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def end_visit(node, parent); end

      # If one of the visitors returns SKIP, stop visiting this node
      sig { params(hooks: T.untyped, node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def self.apply_hooks(hooks, node, parent); end

      class DeleteNode
      end

      # Collect `enter` and `leave` hooks for classes in {GraphQL::Language::Nodes}
      # 
      # Access {NodeVisitor}s via {GraphQL::Language::Visitor#[]}
      class NodeVisitor
        # _@return_ — Hooks to call when entering a node of this type
        sig { returns(T::Array[Proc]) }
        def enter; end

        # _@return_ — Hooks to call when leaving a node of this type
        sig { returns(T::Array[Proc]) }
        def leave; end

        sig { returns(NodeVisitor) }
        def initialize; end

        # Shorthand to add a hook to the {#enter} array
        # 
        # _@param_ `hook` — A hook to add
        sig { params(hook: Proc).returns(T.untyped) }
        def <<(hook); end
      end
    end

    # Exposes {.generate}, which turns AST nodes back into query strings.
    module Generation
      extend GraphQL::Language::Generation

      # Turn an AST node back into a string.
      # 
      # _@param_ `node` — an AST node to recursively stringify
      # 
      # _@param_ `indent` — Whitespace to add to each printed node
      # 
      # _@param_ `printer` — An optional custom printer for printing AST nodes. Defaults to GraphQL::Language::Printer
      # 
      # _@return_ — Valid GraphQL for `node`
      # 
      # Turning a document into a query
      # ```ruby
      # document = GraphQL.parse(query_string)
      # GraphQL::Language::Generation.generate(document)
      # # => "{ ... }"
      # ```
      sig { params(node: GraphQL::Language::Nodes::AbstractNode, indent: String, printer: GraphQL::Language::Printer).returns(String) }
      def generate(node, indent: "", printer: GraphQL::Language::Printer.new); end

      # Turn an AST node back into a string.
      # 
      # _@param_ `node` — an AST node to recursively stringify
      # 
      # _@param_ `indent` — Whitespace to add to each printed node
      # 
      # _@param_ `printer` — An optional custom printer for printing AST nodes. Defaults to GraphQL::Language::Printer
      # 
      # _@return_ — Valid GraphQL for `node`
      # 
      # Turning a document into a query
      # ```ruby
      # document = GraphQL.parse(query_string)
      # GraphQL::Language::Generation.generate(document)
      # # => "{ ... }"
      # ```
      sig { params(node: GraphQL::Language::Nodes::AbstractNode, indent: String, printer: GraphQL::Language::Printer).returns(String) }
      def self.generate(node, indent: "", printer: GraphQL::Language::Printer.new); end
    end

    module BlockString
      # Remove leading and trailing whitespace from a block string.
      # See "Block Strings" in https://github.com/facebook/graphql/blob/master/spec/Section%202%20--%20Language.md
      sig { params(str: T.untyped).returns(T.untyped) }
      def self.trim_whitespace(str); end

      sig { params(str: T.untyped, indent: T.untyped).returns(T.untyped) }
      def self.print(str, indent: ''); end

      sig { params(line: T.untyped, length: T.untyped).returns(T.untyped) }
      def self.break_line(line, length); end
    end

    module DefinitionSlice
      extend GraphQL::Language::DefinitionSlice

      sig { params(document: T.untyped, name: T.untyped).returns(T.untyped) }
      def slice(document, name); end

      sig { params(definitions: T.untyped, name: T.untyped).returns(T.untyped) }
      def find_definition_dependencies(definitions, name); end

      sig { params(document: T.untyped, name: T.untyped).returns(T.untyped) }
      def self.slice(document, name); end

      sig { params(definitions: T.untyped, name: T.untyped).returns(T.untyped) }
      def self.find_definition_dependencies(definitions, name); end
    end

    # @api private
    # 
    # {GraphQL::Language::DocumentFromSchemaDefinition} is used to convert a {GraphQL::Schema} object
    # To a {GraphQL::Language::Document} AST node.
    # 
    # @param context [Hash]
    # @param only [<#call(member, ctx)>]
    # @param except [<#call(member, ctx)>]
    # @param include_introspection_types [Boolean] Whether or not to include introspection types in the AST
    # @param include_built_in_scalars [Boolean] Whether or not to include built in scalars in the AST
    # @param include_built_in_directives [Boolean] Whether or not to include built in directives in the AST
    class DocumentFromSchemaDefinition
      sig do
        params(
          schema: T.untyped,
          context: T.untyped,
          only: T.untyped,
          except: T.untyped,
          include_introspection_types: T.untyped,
          include_built_in_directives: T.untyped,
          include_built_in_scalars: T.untyped,
          always_include_schema: T.untyped
        ).returns(DocumentFromSchemaDefinition)
      end
      def initialize(schema, context: nil, only: nil, except: nil, include_introspection_types: false, include_built_in_directives: false, include_built_in_scalars: false, always_include_schema: false); end

      sig { returns(T.untyped) }
      def document; end

      sig { returns(T.untyped) }
      def build_schema_node; end

      sig { params(object_type: T.untyped).returns(T.untyped) }
      def build_object_type_node(object_type); end

      sig { params(field: T.untyped).returns(T.untyped) }
      def build_field_node(field); end

      sig { params(union_type: T.untyped).returns(T.untyped) }
      def build_union_type_node(union_type); end

      sig { params(interface_type: T.untyped).returns(T.untyped) }
      def build_interface_type_node(interface_type); end

      sig { params(enum_type: T.untyped).returns(T.untyped) }
      def build_enum_type_node(enum_type); end

      sig { params(enum_value: T.untyped).returns(T.untyped) }
      def build_enum_value_node(enum_value); end

      sig { params(scalar_type: T.untyped).returns(T.untyped) }
      def build_scalar_type_node(scalar_type); end

      sig { params(argument: T.untyped).returns(T.untyped) }
      def build_argument_node(argument); end

      sig { params(input_object: T.untyped).returns(T.untyped) }
      def build_input_object_node(input_object); end

      sig { params(directive: T.untyped).returns(T.untyped) }
      def build_directive_node(directive); end

      sig { params(locations: T.untyped).returns(T.untyped) }
      def build_directive_location_nodes(locations); end

      sig { params(location: T.untyped).returns(T.untyped) }
      def build_directive_location_node(location); end

      sig { params(type: T.untyped).returns(T.untyped) }
      def build_type_name_node(type); end

      sig { params(default_value: T.untyped, type: T.untyped).returns(T.untyped) }
      def build_default_value(default_value, type); end

      sig { params(type: T.untyped).returns(T.untyped) }
      def build_type_definition_node(type); end

      sig { params(arguments: T.untyped).returns(T.untyped) }
      def build_argument_nodes(arguments); end

      sig { params(directives: T.untyped).returns(T.untyped) }
      def build_directive_nodes(directives); end

      sig { returns(T.untyped) }
      def build_definition_nodes; end

      sig { params(types: T.untyped).returns(T.untyped) }
      def build_type_definition_nodes(types); end

      sig { params(fields: T.untyped).returns(T.untyped) }
      def build_field_nodes(fields); end

      sig { returns(T::Boolean) }
      def include_schema_node?; end

      sig { params(schema: T.untyped).returns(T::Boolean) }
      def schema_respects_root_name_conventions?(schema); end

      sig { returns(T.untyped) }
      def schema; end

      sig { returns(T.untyped) }
      def warden; end

      sig { returns(T.untyped) }
      def always_include_schema; end

      sig { returns(T.untyped) }
      def include_introspection_types; end

      sig { returns(T.untyped) }
      def include_built_in_directives; end

      sig { returns(T.untyped) }
      def include_built_in_scalars; end
    end
  end

  module Types
    class ID < GraphQL::Schema::Scalar
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, _ctx); end

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_input(value, _ctx); end
    end

    # @see {Types::BigInt} for handling integers outside 32-bit range.
    class Int < GraphQL::Schema::Scalar
      MIN = T.let(-(2**31), T.untyped)
      MAX = T.let((2**31) - 1, T.untyped)
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_input(value, _ctx); end

      sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, ctx); end
    end

    # An untyped JSON scalar that maps to Ruby hashes, arrays, strings, integers, floats, booleans and nils.
    # This should be used judiciously because it subverts the GraphQL type system.
    # 
    # Use it for fields or arguments as follows:
    # 
    #     field :template_parameters, GraphQL::Types::JSON, null: false
    # 
    #     argument :template_parameters, GraphQL::Types::JSON, null: false
    class JSON < GraphQL::Schema::Scalar
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(value: T.untyped, _context: T.untyped).returns(T.untyped) }
      def self.coerce_input(value, _context); end

      sig { params(value: T.untyped, _context: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, _context); end
    end

    class Float < GraphQL::Schema::Scalar
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_input(value, _ctx); end

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, _ctx); end
    end

    # This module contains some types and fields that could support Relay conventions in GraphQL.
    # 
    # You can use these classes out of the box if you want, but if you want to use your _own_
    # GraphQL extensions along with the features in this code, you could also
    # open up the source files and copy the relevant methods and configuration into
    # your own classes.
    # 
    # For example, the provided object types extend {Types::Relay::BaseObject},
    # but you might want to:
    # 
    # 1. Migrate the extensions from {Types::Relay::BaseObject} into _your app's_ base object
    # 2. Copy {Relay::BaseConnection}, {Relay::BaseEdge}, etc into _your app_, and
    #   change them to extend _your_ base object.
    # 
    # Similarly, `BaseField`'s extensions could be migrated to your app
    # and `Node` could be implemented to mix in your base interface module.
    module Relay
      # This can be used for Relay's `Node` interface,
      # or you can take it as inspiration for your own implementation
      # of the `Node` interface.
      module Node
        include GraphQL::Types::Relay::BaseInterface
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        sig { returns(T.untyped) }
        def unwrap; end
      end

      # A class-based definition for Relay edges.
      # 
      # Use this as a parent class in your app, or use it as inspiration for your
      # own base `Edge` class.
      # 
      # For example, you may want to extend your own `BaseObject` instead of the
      # built-in `GraphQL::Schema::Object`.
      # 
      # @example Making a UserEdge type
      #   # Make a base class for your app
      #   class Types::BaseEdge < GraphQL::Types::Relay::BaseEdge
      #   end
      # 
      #   # Then extend your own base class
      #   class Types::UserEdge < Types::BaseEdge
      #     node_type(Types::User)
      #   end
      # 
      # @see {Relay::BaseConnection} for connection types
      class BaseEdge < GraphQL::Types::Relay::BaseObject
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        # Get or set the Object type that this edge wraps.
        # 
        # _@param_ `node_type` — A `Schema::Object` subclass
        # 
        # _@param_ `null` — 
        sig { params(node_type: T.nilable(Class), null: T::Boolean).returns(T.untyped) }
        def self.node_type(node_type = nil, null: true); end

        sig { params(obj: T.untyped, ctx: T.untyped).returns(T::Boolean) }
        def self.authorized?(obj, ctx); end

        sig { params(ctx: T.untyped).returns(T::Boolean) }
        def self.accessible?(ctx); end

        sig { params(ctx: T.untyped).returns(T::Boolean) }
        def self.visible?(ctx); end
      end

      # The return type of a connection's `pageInfo` field
      class PageInfo < GraphQL::Types::Relay::BaseObject
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)
      end

      class BaseField < GraphQL::Schema::Field
        NO_ARGS = T.let({}.freeze, T.untyped)

        sig { params(edge_class: T.untyped, rest: T.untyped, block: T.untyped).returns(BaseField) }
        def initialize(edge_class: nil, **rest, &block); end

        sig { returns(T.untyped) }
        def to_graphql; end
      end

      class BaseObject < GraphQL::Schema::Object
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        sig { params(new_value: T.untyped).returns(T.untyped) }
        def self.default_relay(new_value); end

        sig { returns(T::Boolean) }
        def self.default_relay?; end

        sig { returns(T.untyped) }
        def self.to_graphql; end
      end

      module BaseInterface
        include GraphQL::Schema::Interface
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        sig { returns(T.untyped) }
        def unwrap; end
      end

      # Use this to implement Relay connections, or take it as inspiration
      # for Relay classes in your own app.
      # 
      # You may wish to copy this code into your own base class,
      # so you can extend your own `BaseObject` instead of `GraphQL::Schema::Object`.
      # 
      # @example Implementation a connection and edge
      #   # Given some object in your app ...
      #   class Types::Post < BaseObject
      #   end
      # 
      #   # Make a couple of base classes:
      #   class Types::BaseEdge < GraphQL::Types::Relay::BaseEdge; end
      #   class Types::BaseConnection < GraphQL::Types::Relay::BaseConnection; end
      # 
      #   # Then extend them for the object in your app
      #   class Types::PostEdge < Types::BaseEdge
      #     node_type(Types::Post)
      #   end
      #   class Types::PostConnection < Types::BaseConnection
      #     edge_type(Types::PostEdge)
      #   end
      # 
      # @see Relay::BaseEdge for edge types
      class BaseConnection < GraphQL::Types::Relay::BaseObject
        extend Forwardable
        Boolean = T.let("Boolean", T.untyped)
        ID = T.let("ID", T.untyped)
        Int = T.let("Int", T.untyped)

        sig { returns(Class) }
        def self.node_type; end

        sig { returns(Class) }
        def self.edge_class; end

        # Configure this connection to return `edges` and `nodes` based on `edge_type_class`.
        # 
        # This method will use the inputs to create:
        # - `edges` field
        # - `nodes` field
        # - description
        # 
        # It's called when you subclass this base connection, trying to use the
        # class name to set defaults. You can call it again in the class definition
        # to override the default (or provide a value, if the default lookup failed).
        sig do
          params(
            edge_type_class: T.untyped,
            edge_class: T.untyped,
            node_type: T.untyped,
            nodes_field: T.untyped
          ).returns(T.untyped)
        end
        def self.edge_type(edge_type_class, edge_class: GraphQL::Relay::Edge, node_type: edge_type_class.node_type, nodes_field: true); end

        # Filter this list according to the way its node type would scope them
        sig { params(items: T.untyped, context: T.untyped).returns(T.untyped) }
        def self.scope_items(items, context); end

        # Add the shortcut `nodes` field to this connection and its subclasses
        sig { returns(T.untyped) }
        def self.nodes_field; end

        sig { params(obj: T.untyped, ctx: T.untyped).returns(T::Boolean) }
        def self.authorized?(obj, ctx); end

        sig { params(ctx: T.untyped).returns(T::Boolean) }
        def self.accessible?(ctx); end

        sig { params(ctx: T.untyped).returns(T::Boolean) }
        def self.visible?(ctx); end

        sig { returns(T.untyped) }
        def self.define_nodes_field; end

        # By default this calls through to the ConnectionWrapper's edge nodes method,
        # but sometimes you need to override it to support the `nodes` field
        sig { returns(T.untyped) }
        def nodes; end

        sig { returns(T.untyped) }
        def edges; end
      end
    end

    class String < GraphQL::Schema::Scalar
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, ctx); end

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_input(value, _ctx); end
    end

    class BigInt < GraphQL::Schema::Scalar
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_input(value, _ctx); end

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, _ctx); end
    end

    class Boolean < GraphQL::Schema::Scalar
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_input(value, _ctx); end

      sig { params(value: T.untyped, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, _ctx); end
    end

    # This scalar takes `Date`s and transmits them as strings,
    # using ISO 8601 format.
    # 
    # Use it for fields or arguments as follows:
    # 
    #     field :published_at, GraphQL::Types::ISO8601Date, null: false
    # 
    #     argument :deliver_at, GraphQL::Types::ISO8601Date, null: false
    # 
    # Alternatively, use this built-in scalar as inspiration for your
    # own Date type.
    class ISO8601Date < GraphQL::Schema::Scalar
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # _@param_ `value` — 
      sig { params(value: Date, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, _ctx); end

      # _@param_ `str_value` — 
      sig { params(str_value: T.untyped, _ctx: T.untyped).returns(Date) }
      def self.coerce_input(str_value, _ctx); end
    end

    # This scalar takes `DateTime`s and transmits them as strings,
    # using ISO 8601 format.
    # 
    # Use it for fields or arguments as follows:
    # 
    #     field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    # 
    #     argument :deliver_at, GraphQL::Types::ISO8601DateTime, null: false
    # 
    # Alternatively, use this built-in scalar as inspiration for your
    # own DateTime type.
    class ISO8601DateTime < GraphQL::Schema::Scalar
      DEFAULT_TIME_PRECISION = T.let(0, T.untyped)
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(Integer) }
      def self.time_precision; end

      # _@param_ `value`
      sig { params(value: Integer).returns(T.untyped) }
      def self.time_precision=(value); end

      # _@param_ `value` — 
      sig { params(value: DateTime, _ctx: T.untyped).returns(T.untyped) }
      def self.coerce_result(value, _ctx); end

      # _@param_ `str_value` — 
      sig { params(str_value: T.untyped, _ctx: T.untyped).returns(DateTime) }
      def self.coerce_input(str_value, _ctx); end
    end
  end

  # Wrap unhandled errors with {TracedError}.
  # 
  # {TracedError} provides a GraphQL backtrace with arguments and return values.
  # The underlying error is available as {TracedError#cause}.
  # 
  # WARNING: {.enable} is not threadsafe because {GraphQL::Tracing.install} is not threadsafe.
  # 
  # @example toggling backtrace annotation
  #   # to enable:
  #   GraphQL::Backtrace.enable
  #   # later, to disable:
  #   GraphQL::Backtrace.disable
  class Backtrace
    include Enumerable
    extend Forwardable

    sig { returns(T.untyped) }
    def self.enable; end

    sig { returns(T.untyped) }
    def self.disable; end

    sig { params(schema_defn: T.untyped).returns(T.untyped) }
    def self.use(schema_defn); end

    sig { params(context: T.untyped, value: T.untyped).returns(Backtrace) }
    def initialize(context, value: nil); end

    sig { returns(T.untyped) }
    def inspect; end

    sig { returns(T.untyped) }
    def to_a; end

    # A class for turning a context into a human-readable table or array
    class Table
      MIN_COL_WIDTH = T.let(4, T.untyped)
      MAX_COL_WIDTH = T.let(100, T.untyped)
      HEADERS = T.let([
  "Loc",
  "Field",
  "Object",
  "Arguments",
  "Result",
], T.untyped)

      sig { params(context: T.untyped, value: T.untyped).returns(Table) }
      def initialize(context, value:); end

      # _@return_ — A table layout of backtrace with metadata
      sig { returns(String) }
      def to_table; end

      # _@return_ — An array of position + field name entries
      sig { returns(T::Array[String]) }
      def to_backtrace; end

      sig { returns(T.untyped) }
      def rows; end

      sig { params(rows: T.untyped).returns(String) }
      def render_table(rows); end

      # _@return_ — 5 items for a backtrace table (not `key`)
      sig { params(context_entry: T.untyped, rows: T.untyped, top: T.untyped).returns(T::Array[T.untyped]) }
      def build_rows(context_entry, rows:, top: false); end
    end

    module Tracer
      # Implement the {GraphQL::Tracing} API.
      sig { params(key: T.untyped, metadata: T.untyped).returns(T.untyped) }
      def trace(key, metadata); end

      # Implement the {GraphQL::Tracing} API.
      sig { params(key: T.untyped, metadata: T.untyped).returns(T.untyped) }
      def self.trace(key, metadata); end
    end

    # When {Backtrace} is enabled, raised errors are wrapped with {TracedError}.
    class TracedError < GraphQL::Error
      CAUSE_BACKTRACE_PREVIEW_LENGTH = T.let(10, T.untyped)

      # _@return_ — Printable backtrace of GraphQL error context
      sig { returns(T::Array[String]) }
      def graphql_backtrace; end

      # _@return_ — The context at the field where the error was raised
      sig { returns(GraphQL::Query::Context) }
      def context; end

      sig { params(err: T.untyped, current_ctx: T.untyped).returns(TracedError) }
      def initialize(err, current_ctx); end
    end

    module InspectResult
      sig { params(obj: T.untyped).returns(T.untyped) }
      def inspect_result(obj); end

      sig { params(obj: T.untyped).returns(T.untyped) }
      def self.inspect_result(obj); end

      sig { params(obj: T.untyped).returns(T.untyped) }
      def inspect_truncated(obj); end

      sig { params(obj: T.untyped).returns(T.untyped) }
      def self.inspect_truncated(obj); end
    end
  end

  # The parent for all type classes.
  class BaseType
    include GraphQL::Define::NonNullWithBang
    include GraphQL::Define::InstanceDefinable
    include GraphQL::Relay::TypeExtensions

    # Returns the value of attribute ast_node
    sig { returns(T.untyped) }
    def ast_node; end

    # Sets the attribute ast_node
    # 
    # _@param_ `value` — the value to set the attribute ast_node to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def ast_node=(value); end

    sig { returns(BaseType) }
    def initialize; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    # _@return_ — the name of this type, must be unique within a Schema
    sig { returns(String) }
    def name; end

    sig { returns(T.untyped) }
    def type_class; end

    sig { params(name: String).returns(T.untyped) }
    def name=(name); end

    # _@return_ — a description for this type
    sig { returns(T.nilable(String)) }
    def description; end

    # _@return_ — a description for this type
    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def description=(value); end

    # _@return_ — Is this type a predefined introspection type?
    sig { returns(T::Boolean) }
    def introspection?; end

    # _@return_ — Is this type a built-in scalar type? (eg, `String`, `Int`)
    sig { returns(T::Boolean) }
    def default_scalar?; end

    # _@return_ — Is this type a built-in Relay type? (`Node`, `PageInfo`)
    sig { returns(T::Boolean) }
    def default_relay?; end

    sig { params(value: T.untyped).returns(T.untyped) }
    def introspection=(value); end

    sig { params(value: T.untyped).returns(T.untyped) }
    def default_scalar=(value); end

    sig { params(value: T.untyped).returns(T.untyped) }
    def default_relay=(value); end

    # _@param_ `other` — compare to this object
    # 
    # _@return_ — are these types equivalent? (incl. non-null, list)
    # 
    # _@see_ `{ModifiesAnotherType#==}` — for override on List & NonNull types
    sig { params(other: GraphQL::BaseType).returns(T::Boolean) }
    def ==(other); end

    # If this type is modifying an underlying type,
    # return the underlying type. (Otherwise, return `self`.)
    sig { returns(T.untyped) }
    def unwrap; end

    # _@return_ — a non-null version of this type
    sig { returns(GraphQL::NonNullType) }
    def to_non_null_type; end

    # _@return_ — a list version of this type
    sig { returns(GraphQL::ListType) }
    def to_list_type; end

    # Find out which possible type to use for `value`.
    # Returns self if there are no possible types (ie, not Union or Interface)
    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def resolve_type(value, ctx); end

    # Print the human-readable name of this type using the query-string naming pattern
    sig { returns(T.untyped) }
    def to_s; end

    sig { params(value: T.untyped).returns(T::Boolean) }
    def valid_isolated_input?(value); end

    sig { params(value: T.untyped).returns(T.untyped) }
    def validate_isolated_input(value); end

    sig { params(value: T.untyped).returns(T.untyped) }
    def coerce_isolated_input(value); end

    sig { params(value: T.untyped).returns(T.untyped) }
    def coerce_isolated_result(value); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T::Boolean) }
    def valid_input?(value, ctx = nil); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def validate_input(value, ctx = nil); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_input(value, ctx = nil); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_result(value, ctx); end

    # Types with fields may override this
    # 
    # _@param_ `name` — field name to lookup for this type
    sig { params(name: String).returns(T.nilable(GraphQL::Field)) }
    def get_field(name); end

    # During schema definition, types can be defined inside procs or as strings.
    # This function converts it to a type instance
    sig { params(type_arg: T.untyped).returns(GraphQL::BaseType) }
    def self.resolve_related_type(type_arg); end

    # Return a GraphQL string for the type definition
    # 
    # _@param_ `schema` — 
    # 
    # _@param_ `printer` — 
    # 
    # _@return_ — type definition
    # 
    # _@see_ `{GraphQL::Schema::Printer#initialize` — for additional options}
    sig { params(schema: GraphQL::Schema, printer: T.nilable(GraphQL::Schema::Printer), args: T.untyped).returns(String) }
    def to_definition(schema, printer: nil, **args); end

    # Returns true if this is a non-nullable type. A nullable list of non-nullables is considered nullable.
    sig { returns(T::Boolean) }
    def non_null?; end

    # Returns true if this is a list type. A non-nullable list is considered a list.
    sig { returns(T::Boolean) }
    def list?; end

    sig { params(alt_method_name: T.untyped).returns(T.untyped) }
    def warn_deprecated_coerce(alt_method_name); end

    # _@return_ — The default connection type for this object type
    sig { returns(GraphQL::ObjectType) }
    def connection_type; end

    # Define a custom connection type for this object type
    sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
    def define_connection(**kwargs, &block); end

    # _@return_ — The default edge type for this object type
    sig { returns(GraphQL::ObjectType) }
    def edge_type; end

    # Define a custom edge type for this object type
    sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
    def define_edge(**kwargs, &block); end

    # `metadata` can store arbitrary key-values with an object.
    # 
    # _@return_ — Hash for user-defined storage
    sig { returns(T::Hash[Object, Object]) }
    def metadata; end

    # Mutate this instance using functions from its {.definition}s.
    # Keywords or helpers in the block correspond to keys given to `accepts_definitions`.
    # 
    # Note that the block is not called right away -- instead, it's deferred until
    # one of the defined fields is needed.
    sig { params(kwargs: T.untyped, block: T.untyped).void }
    def define(**kwargs, &block); end

    # Shallow-copy this object, then apply new definitions to the copy.
    # 
    # _@return_ — A new instance, with any extended definitions
    # 
    # _@see_ `{#define}` — for arguments
    sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::Define::InstanceDefinable) }
    def redefine(**kwargs, &block); end

    # Run the definition block if it hasn't been run yet.
    # This can only be run once: the block is deleted after it's used.
    # You have to call this before using any value which could
    # come from the definition block.
    sig { void }
    def ensure_defined; end

    # Take the pending methods and put them back on this object's singleton class.
    # This reverts the process done by {#stash_dependent_methods}
    sig { void }
    def revive_dependent_methods; end

    # Find the method names which were declared as definition-dependent,
    # then grab the method definitions off of this object's class
    # and store them for later.
    # 
    # Then make a dummy method for each of those method names which:
    # 
    # - Triggers the pending definition, if there is one
    # - Calls the same method again.
    # 
    # It's assumed that {#ensure_defined} will put the original method definitions
    # back in place with {#revive_dependent_methods}.
    sig { void }
    def stash_dependent_methods; end

    # Make the type non-null
    # 
    # _@return_ — a non-null type which wraps the original type
    sig { returns(GraphQL::NonNullType) }
    def !; end

    module ModifiesAnotherType
      sig { returns(T.untyped) }
      def unwrap; end

      sig { params(other: T.untyped).returns(T.untyped) }
      def ==(other); end
    end
  end

  # Directives are server-defined hooks for modifying execution.
  # 
  # Two directives are included out-of-the-box:
  # - `@skip(if: ...)` Skips the tagged field if the value of `if` is true
  # - `@include(if: ...)` Includes the tagged field _only_ if `if` is true
  class Directive
    include GraphQL::Define::InstanceDefinable
    SkipDirective = T.let(GraphQL::Schema::Directive::Skip.graphql_definition, T.untyped)
    IncludeDirective = T.let(GraphQL::Schema::Directive::Include.graphql_definition, T.untyped)
    DeprecatedDirective = T.let(GraphQL::Directive.define do
  name "deprecated"
  description "Marks an element of a GraphQL schema as no longer supported."
  locations([GraphQL::Directive::FIELD_DEFINITION, GraphQL::Directive::ENUM_VALUE])

  reason_description = "Explains why this element was deprecated, usually also including a "\
    "suggestion for how to access supported similar data. Formatted "\
    "in [Markdown](https://daringfireball.net/projects/markdown/)."

  argument :reason, GraphQL::STRING_TYPE, reason_description, default_value: GraphQL::Directive::DEFAULT_DEPRECATION_REASON
  default_directive true
end, T.untyped)

    # Returns the value of attribute locations
    sig { returns(T.untyped) }
    def locations; end

    # Sets the attribute locations
    # 
    # _@param_ `value` — the value to set the attribute locations to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def locations=(value); end

    # Returns the value of attribute arguments
    sig { returns(T.untyped) }
    def arguments; end

    # Sets the attribute arguments
    # 
    # _@param_ `value` — the value to set the attribute arguments to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def arguments=(value); end

    # Returns the value of attribute name
    sig { returns(T.untyped) }
    def name; end

    # Sets the attribute name
    # 
    # _@param_ `value` — the value to set the attribute name to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def name=(value); end

    # Returns the value of attribute description
    sig { returns(T.untyped) }
    def description; end

    # Sets the attribute description
    # 
    # _@param_ `value` — the value to set the attribute description to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def description=(value); end

    # Returns the value of attribute arguments_class
    sig { returns(T.untyped) }
    def arguments_class; end

    # Sets the attribute arguments_class
    # 
    # _@param_ `value` — the value to set the attribute arguments_class to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def arguments_class=(value); end

    # Returns the value of attribute ast_node
    sig { returns(T.untyped) }
    def ast_node; end

    # Sets the attribute ast_node
    # 
    # _@param_ `value` — the value to set the attribute ast_node to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def ast_node=(value); end

    sig { params(value: T.untyped).returns(T.untyped) }
    def default_directive=(value); end

    sig { returns(Directive) }
    def initialize; end

    sig { returns(T.untyped) }
    def to_s; end

    sig { returns(T::Boolean) }
    def on_field?; end

    sig { returns(T::Boolean) }
    def on_fragment?; end

    sig { returns(T::Boolean) }
    def on_operation?; end

    # _@return_ — Is this directive supplied by default? (eg `@skip`)
    sig { returns(T::Boolean) }
    def default_directive?; end

    sig { returns(T.untyped) }
    def inspect; end

    # `metadata` can store arbitrary key-values with an object.
    # 
    # _@return_ — Hash for user-defined storage
    sig { returns(T::Hash[Object, Object]) }
    def metadata; end

    # Mutate this instance using functions from its {.definition}s.
    # Keywords or helpers in the block correspond to keys given to `accepts_definitions`.
    # 
    # Note that the block is not called right away -- instead, it's deferred until
    # one of the defined fields is needed.
    sig { params(kwargs: T.untyped, block: T.untyped).void }
    def define(**kwargs, &block); end

    # Shallow-copy this object, then apply new definitions to the copy.
    # 
    # _@return_ — A new instance, with any extended definitions
    # 
    # _@see_ `{#define}` — for arguments
    sig { params(kwargs: T.untyped, block: T.untyped).returns(T.untyped) }
    def redefine(**kwargs, &block); end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    # Run the definition block if it hasn't been run yet.
    # This can only be run once: the block is deleted after it's used.
    # You have to call this before using any value which could
    # come from the definition block.
    sig { void }
    def ensure_defined; end

    # Take the pending methods and put them back on this object's singleton class.
    # This reverts the process done by {#stash_dependent_methods}
    sig { void }
    def revive_dependent_methods; end

    # Find the method names which were declared as definition-dependent,
    # then grab the method definitions off of this object's class
    # and store them for later.
    # 
    # Then make a dummy method for each of those method names which:
    # 
    # - Triggers the pending definition, if there is one
    # - Calls the same method again.
    # 
    # It's assumed that {#ensure_defined} will put the original method definitions
    # back in place with {#revive_dependent_methods}.
    sig { void }
    def stash_dependent_methods; end
  end

  # Represents a collection of related values.
  # By convention, enum names are `SCREAMING_CASE_NAMES`,
  # but other identifiers are supported too.
  # 
  # You can use as return types _or_ as inputs.
  # 
  # By default, enums are passed to `resolve` functions as
  # the strings that identify them, but you can provide a
  # custom Ruby value with the `value:` keyword.
  # 
  # @example An enum of programming languages
  #   LanguageEnum = GraphQL::EnumType.define do
  #     name "Language"
  #     description "Programming language for Web projects"
  #     value("PYTHON", "A dynamic, function-oriented language")
  #     value("RUBY", "A very dynamic language aimed at programmer happiness")
  #     value("JAVASCRIPT", "Accidental lingua franca of the web")
  #   end
  # 
  # @example Using an enum as a return type
  #    field :favoriteLanguage, LanguageEnum, "This person's favorite coding language"
  #    # ...
  #    # In a query:
  #    Schema.execute("{ coder(id: 1) { favoriteLanguage } }")
  #    # { "data" => { "coder" => { "favoriteLanguage" => "RUBY" } } }
  # 
  # @example Defining an enum input
  #    field :coders, types[CoderType] do
  #      argument :knowing, types[LanguageEnum]
  #      resolve ->(obj, args, ctx) {
  #        Coder.where(language: args[:knowing])
  #      }
  #    end
  # 
  # @example Using an enum as input
  #   {
  #     # find coders who know Python and Ruby
  #     coders(knowing: [PYTHON, RUBY]) {
  #       name
  #       hourlyRate
  #     }
  #   }
  # 
  # @example Enum whose values are different in Ruby-land
  #   GraphQL::EnumType.define do
  #     # ...
  #     # use the `value:` keyword:
  #     value("RUBY", "Lisp? Smalltalk?", value: :rb)
  #   end
  # 
  #   # Now, resolve functions will receive `:rb` instead of `"RUBY"`
  #   field :favoriteLanguage, LanguageEnum
  #   resolve ->(obj, args, ctx) {
  #     args[:favoriteLanguage] # => :rb
  #   }
  # 
  # @example Enum whose values are different in ActiveRecord-land
  #   class Language < ActiveRecord::Base
  #     enum language: {
  #       rb: 0
  #     }
  #   end
  # 
  #   # Now enum type should be defined as
  #   GraphQL::EnumType.define do
  #     # ...
  #     # use the `value:` keyword:
  #     value("RUBY", "Lisp? Smalltalk?", value: 'rb')
  #   end
  class EnumType < GraphQL::BaseType
    # Returns the value of attribute ast_node
    sig { returns(T.untyped) }
    def ast_node; end

    # Sets the attribute ast_node
    # 
    # _@param_ `value` — the value to set the attribute ast_node to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def ast_node=(value); end

    sig { returns(EnumType) }
    def initialize; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    # _@param_ `new_values` — The set of values contained in this type
    sig { params(new_values: T::Array[EnumValue]).returns(T.untyped) }
    def values=(new_values); end

    # _@param_ `enum_value` — A value to add to this type's set of values
    sig { params(enum_value: EnumValue).returns(T.untyped) }
    def add_value(enum_value); end

    # _@return_ — `{name => value}` pairs contained in this type
    sig { returns(T::Hash[String, EnumValue]) }
    def values; end

    sig { returns(T.untyped) }
    def kind; end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_result(value, ctx = nil); end

    sig { returns(T.untyped) }
    def to_s; end

    # Get the underlying value for this enum value
    # 
    # _@param_ `value_name` — the string representation of this enum value
    # 
    # _@return_ — the underlying value for this enum value
    # 
    # get episode value from Enum
    # ```ruby
    # episode = EpisodeEnum.coerce("NEWHOPE")
    # episode # => 6
    # ```
    sig { params(value_name: String, ctx: T.untyped).returns(Object) }
    def coerce_non_null_input(value_name, ctx); end

    sig { params(value_name: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def validate_non_null_input(value_name, ctx); end

    # A value within an {EnumType}
    # 
    # Created with the `value` helper
    class EnumValue
      include GraphQL::Define::InstanceDefinable
      ATTRIBUTES = T.let([:name, :description, :deprecation_reason, :value], T.untyped)

      # Returns the value of attribute ast_node
      sig { returns(T.untyped) }
      def ast_node; end

      # Sets the attribute ast_node
      # 
      # _@param_ `value` — the value to set the attribute ast_node to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def ast_node=(value); end

      sig { params(new_name: T.untyped).returns(T.untyped) }
      def name=(new_name); end

      sig { returns(T.untyped) }
      def graphql_name; end

      sig { returns(T.untyped) }
      def type_class; end

      # `metadata` can store arbitrary key-values with an object.
      # 
      # _@return_ — Hash for user-defined storage
      sig { returns(T::Hash[Object, Object]) }
      def metadata; end

      # Mutate this instance using functions from its {.definition}s.
      # Keywords or helpers in the block correspond to keys given to `accepts_definitions`.
      # 
      # Note that the block is not called right away -- instead, it's deferred until
      # one of the defined fields is needed.
      sig { params(kwargs: T.untyped, block: T.untyped).void }
      def define(**kwargs, &block); end

      # Shallow-copy this object, then apply new definitions to the copy.
      # 
      # _@return_ — A new instance, with any extended definitions
      # 
      # _@see_ `{#define}` — for arguments
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::Define::InstanceDefinable) }
      def redefine(**kwargs, &block); end

      sig { params(other: T.untyped).returns(T.untyped) }
      def initialize_copy(other); end

      # Run the definition block if it hasn't been run yet.
      # This can only be run once: the block is deleted after it's used.
      # You have to call this before using any value which could
      # come from the definition block.
      sig { void }
      def ensure_defined; end

      # Take the pending methods and put them back on this object's singleton class.
      # This reverts the process done by {#stash_dependent_methods}
      sig { void }
      def revive_dependent_methods; end

      # Find the method names which were declared as definition-dependent,
      # then grab the method definitions off of this object's class
      # and store them for later.
      # 
      # Then make a dummy method for each of those method names which:
      # 
      # - Triggers the pending definition, if there is one
      # - Calls the same method again.
      # 
      # It's assumed that {#ensure_defined} will put the original method definitions
      # back in place with {#revive_dependent_methods}.
      sig { void }
      def stash_dependent_methods; end
    end

    class UnresolvedValueError < GraphQL::Error
    end
  end

  # A list type modifies another type.
  # 
  # List types can be created with the type helper (`types[InnerType]`)
  # or {BaseType#to_list_type} (`InnerType.to_list_type`)
  # 
  # For return types, it says that the returned value will be a list of the modified.
  # 
  # @example A field which returns a list of items
  #   field :items, types[ItemType]
  #   # or
  #   field :items, ItemType.to_list_type
  # 
  # For input types, it says that the incoming value will be a list of the modified type.
  # 
  # @example A field which accepts a list of strings
  #   field :newNames do
  #     # ...
  #     argument :values, types[types.String]
  #     # or
  #     argument :values, types.String.to_list_type
  #   end
  # 
  # Given a list type, you can always get the underlying type with {#unwrap}.
  class ListType < GraphQL::BaseType
    include GraphQL::BaseType::ModifiesAnotherType

    # Returns the value of attribute of_type
    sig { returns(T.untyped) }
    def of_type; end

    sig { params(of_type: T.untyped).returns(ListType) }
    def initialize(of_type:); end

    sig { returns(T.untyped) }
    def kind; end

    sig { returns(T.untyped) }
    def to_s; end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_result(value, ctx = nil); end

    sig { returns(T::Boolean) }
    def list?; end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_non_null_input(value, ctx); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def validate_non_null_input(value, ctx); end

    sig { params(value: T.untyped).returns(T.untyped) }
    def ensure_array(value); end

    sig { returns(T.untyped) }
    def unwrap; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def ==(other); end
  end

  # A rake task for dumping a schema as IDL or JSON.
  # 
  # By default, schemas are looked up by name as constants using `schema_name:`.
  # You can provide a `load_schema` function to return your schema another way.
  # 
  # `load_context:`, `only:` and `except:` are supported so that
  # you can keep an eye on how filters affect your schema.
  # 
  # @example Dump a Schema to .graphql + .json files
  #   require "graphql/rake_task"
  #   GraphQL::RakeTask.new(schema_name: "MySchema")
  # 
  #   # $ rake graphql:schema:dump
  #   # Schema IDL dumped to ./schema.graphql
  #   # Schema JSON dumped to ./schema.json
  # 
  # @example Invoking the task from Ruby
  #   require "rake"
  #   Rake::Task["graphql:schema:dump"].invoke
  class RakeTask
    include Rake::DSL
    extend Rake::DSL
    DEFAULT_OPTIONS = T.let({
  namespace: "graphql",
  dependencies: nil,
  schema_name: nil,
  load_schema: ->(task) { Object.const_get(task.schema_name) },
  load_context: ->(task) { {} },
  only: nil,
  except: nil,
  directory: ".",
  idl_outfile: "schema.graphql",
  json_outfile: "schema.json",
}, T.untyped)

    # _@return_ — Namespace for generated tasks
    sig { params(value: T.untyped).returns(String) }
    def namespace=(value); end

    sig { returns(T.untyped) }
    def rake_namespace; end

    sig { returns(T::Array[String]) }
    def dependencies; end

    sig { params(value: T::Array[String]).returns(T::Array[String]) }
    def dependencies=(value); end

    # _@return_ — By default, used to find the schema as a constant.
    # 
    # _@see_ `{#load_schema}` — for loading a schema another way
    sig { returns(String) }
    def schema_name; end

    # _@return_ — By default, used to find the schema as a constant.
    # 
    # _@see_ `{#load_schema}` — for loading a schema another way
    sig { params(value: String).returns(String) }
    def schema_name=(value); end

    # _@return_ — A proc for loading the target GraphQL schema
    sig { returns(T::Array[T.untyped]) }
    def load_schema; end

    # _@return_ — A proc for loading the target GraphQL schema
    sig { params(value: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
    def load_schema=(value); end

    # _@return_ — A callable for loading the query context
    sig { returns(T::Array[T.untyped]) }
    def load_context; end

    # _@return_ — A callable for loading the query context
    sig { params(value: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
    def load_context=(value); end

    # _@return_ — A filter for this task
    sig { returns(T.nilable(T::Array[T.untyped])) }
    def only; end

    # _@return_ — A filter for this task
    sig { params(value: T.nilable(T::Array[T.untyped])).returns(T.nilable(T::Array[T.untyped])) }
    def only=(value); end

    # _@return_ — A filter for this task
    sig { returns(T.nilable(T::Array[T.untyped])) }
    def except; end

    # _@return_ — A filter for this task
    sig { params(value: T.nilable(T::Array[T.untyped])).returns(T.nilable(T::Array[T.untyped])) }
    def except=(value); end

    # _@return_ — target for IDL task
    sig { returns(String) }
    def idl_outfile; end

    # _@return_ — target for IDL task
    sig { params(value: String).returns(String) }
    def idl_outfile=(value); end

    # _@return_ — target for JSON task
    sig { returns(String) }
    def json_outfile; end

    # _@return_ — target for JSON task
    sig { params(value: String).returns(String) }
    def json_outfile=(value); end

    # _@return_ — directory for IDL & JSON files
    sig { returns(String) }
    def directory; end

    # _@return_ — directory for IDL & JSON files
    sig { params(value: String).returns(String) }
    def directory=(value); end

    # Set the parameters of this task by passing keyword arguments
    # or assigning attributes inside the block
    sig { params(options: T.untyped).returns(RakeTask) }
    def initialize(options = {}); end

    # Use the provided `method_name` to generate a string from the specified schema
    # then write it to `file`.
    sig { params(method_name: T.untyped, file: T.untyped).returns(T.untyped) }
    def write_outfile(method_name, file); end

    sig { returns(T.untyped) }
    def idl_path; end

    sig { returns(T.untyped) }
    def json_path; end

    # Use the Rake DSL to add tasks
    sig { returns(T.untyped) }
    def define_task; end
  end

  module Relay
    PageInfo = T.let(GraphQL::Types::Relay::PageInfo.graphql_definition, T.untyped)

    # Mostly an internal concern.
    # 
    # Wraps an object as a `node`, and exposes a connection-specific `cursor`.
    class Edge
      # Returns the value of attribute node
      sig { returns(T.untyped) }
      def node; end

      # Returns the value of attribute connection
      sig { returns(T.untyped) }
      def connection; end

      sig { params(node: T.untyped, connection: T.untyped).returns(Edge) }
      def initialize(node, connection); end

      sig { returns(T.untyped) }
      def cursor; end

      sig { returns(T.untyped) }
      def parent; end

      sig { returns(T.untyped) }
      def inspect; end
    end

    # Helpers for working with Relay-specific Node objects.
    module Node
      # _@return_ — a field for finding objects by their global ID.
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::Field) }
      def self.field(**kwargs, &block); end

      sig { params(kwargs: T.untyped, block: T.untyped).returns(T.untyped) }
      def self.plural_field(**kwargs, &block); end

      # _@return_ — The interface which all Relay types must implement
      sig { returns(GraphQL::InterfaceType) }
      def self.interface; end
    end

    # Define a Relay mutation:
    #   - give it a name (used for derived inputs & outputs)
    #   - declare its inputs
    #   - declare its outputs
    #   - declare the mutation procedure
    # 
    # `resolve` should return a hash with a key for each of the `return_field`s
    # 
    # Inputs may also contain a `clientMutationId`
    # 
    # @example Updating the name of an item
    #   UpdateNameMutation = GraphQL::Relay::Mutation.define do
    #     name "UpdateName"
    # 
    #     input_field :name, !types.String
    #     input_field :itemId, !types.ID
    # 
    #     return_field :item, ItemType
    # 
    #     resolve ->(inputs, ctx) {
    #       item = Item.find_by_id(inputs[:id])
    #       item.update(name: inputs[:name])
    #       {item: item}
    #     }
    #   end
    # 
    #   MutationType = GraphQL::ObjectType.define do
    #     # The mutation object exposes a field:
    #     field :updateName, field: UpdateNameMutation.field
    #   end
    # 
    #   # Then query it:
    #   query_string = %|
    #     mutation updateName {
    #       updateName(input: {itemId: 1, name: "new name", clientMutationId: "1234"}) {
    #         item { name }
    #         clientMutationId
    #     }|
    # 
    #    GraphQL::Query.new(MySchema, query_string).result
    #    # {"data" => {
    #    #   "updateName" => {
    #    #     "item" => { "name" => "new name"},
    #    #     "clientMutationId" => "1234"
    #    #   }
    #    # }}
    # 
    # @example Using a GraphQL::Function
    #   class UpdateAttributes < GraphQL::Function
    #     attr_reader :model, :return_as, :arguments
    # 
    #     def initialize(model:, return_as:, attributes:)
    #       @model = model
    #       @arguments = {}
    #       attributes.each do |name, type|
    #         arg_name = name.to_s
    #         @arguments[arg_name] = GraphQL::Argument.define(name: arg_name, type: type)
    #       end
    #       @arguments["id"] = GraphQL::Argument.define(name: "id", type: !GraphQL::ID_TYPE)
    #       @return_as = return_as
    #       @attributes = attributes
    #     end
    # 
    #     def type
    #       fn = self
    #       GraphQL::ObjectType.define do
    #         name "Update#{fn.model.name}AttributesResponse"
    #         field :clientMutationId, types.ID
    #         field fn.return_as.keys[0], fn.return_as.values[0]
    #       end
    #     end
    # 
    #     def call(obj, args, ctx)
    #       record = @model.find(args[:inputs][:id])
    #       new_values = {}
    #       @attributes.each { |a| new_values[a] = args[a] }
    #       record.update(new_values)
    #       { @return_as => record }
    #     end
    #   end
    # 
    #   UpdateNameMutation = GraphQL::Relay::Mutation.define do
    #     name "UpdateName"
    #     function UpdateAttributes.new(model: Item, return_as: { item: ItemType }, attributes: {name: !types.String})
    #   end
    class Mutation
      include GraphQL::Define::InstanceDefinable

      # Returns the value of attribute name
      sig { returns(T.untyped) }
      def name; end

      # Sets the attribute name
      # 
      # _@param_ `value` — the value to set the attribute name to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def name=(value); end

      # Returns the value of attribute description
      sig { returns(T.untyped) }
      def description; end

      # Sets the attribute description
      # 
      # _@param_ `value` — the value to set the attribute description to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def description=(value); end

      # Returns the value of attribute fields
      sig { returns(T.untyped) }
      def fields; end

      # Sets the attribute fields
      # 
      # _@param_ `value` — the value to set the attribute fields to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def fields=(value); end

      # Returns the value of attribute arguments
      sig { returns(T.untyped) }
      def arguments; end

      # Sets the attribute arguments
      # 
      # _@param_ `value` — the value to set the attribute arguments to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def arguments=(value); end

      # Sets the attribute return_type
      # 
      # _@param_ `value` — the value to set the attribute return_type to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def return_type=(value); end

      # Sets the attribute return_interfaces
      # 
      # _@param_ `value` — the value to set the attribute return_interfaces to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def return_interfaces=(value); end

      sig { returns(Mutation) }
      def initialize; end

      sig { returns(T::Boolean) }
      def has_generated_return_type?; end

      sig { params(new_resolve_proc: T.untyped).returns(T.untyped) }
      def resolve=(new_resolve_proc); end

      sig { returns(T.untyped) }
      def field; end

      sig { returns(T.untyped) }
      def return_interfaces; end

      sig { returns(T.untyped) }
      def return_type; end

      sig { returns(T.untyped) }
      def input_type; end

      sig { returns(T.untyped) }
      def result_class; end

      # `metadata` can store arbitrary key-values with an object.
      # 
      # _@return_ — Hash for user-defined storage
      sig { returns(T::Hash[Object, Object]) }
      def metadata; end

      # Mutate this instance using functions from its {.definition}s.
      # Keywords or helpers in the block correspond to keys given to `accepts_definitions`.
      # 
      # Note that the block is not called right away -- instead, it's deferred until
      # one of the defined fields is needed.
      sig { params(kwargs: T.untyped, block: T.untyped).void }
      def define(**kwargs, &block); end

      # Shallow-copy this object, then apply new definitions to the copy.
      # 
      # _@return_ — A new instance, with any extended definitions
      # 
      # _@see_ `{#define}` — for arguments
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::Define::InstanceDefinable) }
      def redefine(**kwargs, &block); end

      sig { params(other: T.untyped).returns(T.untyped) }
      def initialize_copy(other); end

      # Run the definition block if it hasn't been run yet.
      # This can only be run once: the block is deleted after it's used.
      # You have to call this before using any value which could
      # come from the definition block.
      sig { void }
      def ensure_defined; end

      # Take the pending methods and put them back on this object's singleton class.
      # This reverts the process done by {#stash_dependent_methods}
      sig { void }
      def revive_dependent_methods; end

      # Find the method names which were declared as definition-dependent,
      # then grab the method definitions off of this object's class
      # and store them for later.
      # 
      # Then make a dummy method for each of those method names which:
      # 
      # - Triggers the pending definition, if there is one
      # - Calls the same method again.
      # 
      # It's assumed that {#ensure_defined} will put the original method definitions
      # back in place with {#revive_dependent_methods}.
      sig { void }
      def stash_dependent_methods; end

      # Use this when the mutation's return type was generated from `return_field`s.
      # It delegates field lookups to the hash returned from `resolve`.
      # @api private
      class Result
        sig { returns(T.untyped) }
        def client_mutation_id; end

        sig { params(client_mutation_id: T.untyped, result: T.untyped).returns(Result) }
        def initialize(client_mutation_id:, result:); end

        sig { returns(T.untyped) }
        def self.mutation; end

        sig { params(value: T.untyped).returns(T.untyped) }
        def self.mutation=(value); end

        # Build a subclass whose instances have a method
        # for each of `mutation_defn`'s `return_field`s
        # 
        # _@param_ `mutation_defn` — 
        sig { params(mutation_defn: GraphQL::Relay::Mutation).returns(Class) }
        def self.define_subclass(mutation_defn); end
      end

      # Wrap a user-provided resolve function,
      # wrapping the returned value in a {Mutation::Result}.
      # Also, pass the `clientMutationId` to that result object.
      # @api private
      class Resolve
        sig { params(mutation: T.untyped, resolve: T.untyped).returns(Resolve) }
        def initialize(mutation, resolve); end

        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def call(obj, args, ctx); end

        sig { params(mutation_result: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def build_result(mutation_result, args, ctx); end
      end

      # @api private
      module Instrumentation
        # Modify mutation `return_field` resolves by wrapping the returned object
        # in a {Mutation::Result}.
        # 
        # By using an instrumention, we can apply our wrapper _last_,
        # giving users access to the original resolve function in earlier instrumentation.
        sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
        def self.instrument(type, field); end
      end
    end

    module EdgeType
      sig { params(wrapped_type: T.untyped, name: T.untyped, block: T.untyped).returns(T.untyped) }
      def self.create_type(wrapped_type, name: nil, &block); end
    end

    # This provides some isolation from `GraphQL::Relay` internals.
    # 
    # Given a list of items and a new item, it will provide a connection and an edge.
    # 
    # The connection doesn't receive outside arguments, so the list of items
    # should be ordered and paginated before providing it here.
    # 
    # @example Adding a comment to list of comments
    #   post = Post.find(args[:postId])
    #   comments = post.comments
    #   new_comment = comments.build(body: args[:body])
    #   new_comment.save!
    # 
    #   range_add = GraphQL::Relay::RangeAdd.new(
    #     parent: post,
    #     collection: comments,
    #     item: new_comment,
    #     context: ctx,
    #   )
    # 
    #   response = {
    #     post: post,
    #     commentsConnection: range_add.connection,
    #     newCommentEdge: range_add.edge,
    #   }
    class RangeAdd
      # Returns the value of attribute edge
      sig { returns(T.untyped) }
      def edge; end

      # Returns the value of attribute connection
      sig { returns(T.untyped) }
      def connection; end

      # Returns the value of attribute parent
      sig { returns(T.untyped) }
      def parent; end

      # _@param_ `collection` — The list of items to wrap in a connection
      # 
      # _@param_ `item` — The newly-added item (will be wrapped in `edge_class`)
      # 
      # _@param_ `parent` — The owner of `collection`, will be passed to the connection if provided
      # 
      # _@param_ `context` — The surrounding `ctx`, will be passed to the connection if provided (this is required for cursor encoders)
      # 
      # _@param_ `edge_class` — The class to wrap `item` with
      sig do
        params(
          collection: Object,
          item: Object,
          parent: T.nilable(Object),
          context: T.nilable(GraphQL::Query::Context),
          edge_class: Class
        ).returns(RangeAdd)
      end
      def initialize(collection:, item:, parent: nil, context: nil, edge_class: Relay::Edge); end
    end

    # Subclasses must implement:
    #   - {#cursor_from_node}, which returns an opaque cursor for the given item
    #   - {#sliced_nodes}, which slices by `before` & `after`
    #   - {#paged_nodes}, which applies `first` & `last` limits
    # 
    # In a subclass, you have access to
    #   - {#nodes}, the collection which the connection will wrap
    #   - {#first}, {#after}, {#last}, {#before} (arguments passed to the field)
    #   - {#max_page_size} (the specified maximum page size that can be returned from a connection)
    class BaseConnection
      CURSOR_SEPARATOR = T.let("---", T.untyped)
      CONNECTION_IMPLEMENTATIONS = T.let({}, T.untyped)

      # Find a connection implementation suitable for exposing `nodes`
      # 
      # _@param_ `nodes` — A collection of nodes (eg, Array, AR::Relation)
      # 
      # _@return_ — a connection Class for wrapping `nodes`
      sig { params(nodes: Object).returns(T.untyped) }
      def self.connection_for_nodes(nodes); end

      # Add `connection_class` as the connection wrapper for `nodes_class`
      # eg, `RelationConnection` is the implementation for `AR::Relation`
      # 
      # _@param_ `nodes_class` — A class representing a collection (eg, Array, AR::Relation)
      # 
      # _@param_ `connection_class` — A class implementing Connection methods
      sig { params(nodes_class: Class, connection_class: Class).returns(T.untyped) }
      def self.register_connection_implementation(nodes_class, connection_class); end

      # Returns the value of attribute nodes
      sig { returns(T.untyped) }
      def nodes; end

      # Returns the value of attribute arguments
      sig { returns(T.untyped) }
      def arguments; end

      # Returns the value of attribute max_page_size
      sig { returns(T.untyped) }
      def max_page_size; end

      # Returns the value of attribute parent
      sig { returns(T.untyped) }
      def parent; end

      # Returns the value of attribute field
      sig { returns(T.untyped) }
      def field; end

      # Returns the value of attribute context
      sig { returns(T.untyped) }
      def context; end

      # Make a connection, wrapping `nodes`
      # 
      # _@param_ `nodes` — The collection of nodes
      # 
      # _@param_ `arguments` — Query arguments
      # 
      # _@param_ `field` — The underlying field
      # 
      # _@param_ `max_page_size` — The maximum number of results to return
      # 
      # _@param_ `parent` — The object which this collection belongs to
      # 
      # _@param_ `context` — The context from the field being resolved
      sig do
        params(
          nodes: Object,
          arguments: GraphQL::Query::Arguments,
          field: T.nilable(GraphQL::Field),
          max_page_size: T.nilable(GraphQL::Types::Int),
          parent: T.nilable(Object),
          context: T.nilable(GraphQL::Query::Context)
        ).returns(BaseConnection)
      end
      def initialize(nodes, arguments, field: nil, max_page_size: nil, parent: nil, context: nil); end

      sig { params(data: T.untyped).returns(T.untyped) }
      def encode(data); end

      sig { params(data: T.untyped).returns(T.untyped) }
      def decode(data); end

      # The value passed as `first:`, if there was one. Negative numbers become `0`.
      sig { returns(T.nilable(Integer)) }
      def first; end

      # The value passed as `after:`, if there was one
      sig { returns(T.nilable(String)) }
      def after; end

      # The value passed as `last:`, if there was one. Negative numbers become `0`.
      sig { returns(T.nilable(Integer)) }
      def last; end

      # The value passed as `before:`, if there was one
      sig { returns(T.nilable(String)) }
      def before; end

      # These are the nodes to render for this connection,
      # probably wrapped by {GraphQL::Relay::Edge}
      sig { returns(T.untyped) }
      def edge_nodes; end

      # Support the `pageInfo` field
      sig { returns(T.untyped) }
      def page_info; end

      # Used by `pageInfo`
      sig { returns(T.untyped) }
      def has_next_page; end

      # Used by `pageInfo`
      sig { returns(T.untyped) }
      def has_previous_page; end

      # Used by `pageInfo`
      sig { returns(T.untyped) }
      def start_cursor; end

      # Used by `pageInfo`
      sig { returns(T.untyped) }
      def end_cursor; end

      # An opaque operation which returns a connection-specific cursor.
      sig { params(object: T.untyped).returns(T.untyped) }
      def cursor_from_node(object); end

      sig { returns(T.untyped) }
      def inspect; end

      # Return a sanitized `arguments[arg_name]` (don't allow negatives)
      sig { params(arg_name: T.untyped).returns(T.untyped) }
      def get_limited_arg(arg_name); end

      sig { returns(T.untyped) }
      def paged_nodes; end

      sig { returns(T.untyped) }
      def sliced_nodes; end
    end

    module ConnectionType
      # _@return_ — If true, connection types get a `nodes` shortcut field
      sig { returns(T::Boolean) }
      def self.default_nodes_field; end

      # _@return_ — If true, connection types get a `nodes` shortcut field
      sig { params(value: T::Boolean).returns(T::Boolean) }
      def self.default_nodes_field=(value); end

      # _@return_ — If true, connections check for reverse-direction `has*Page` values
      sig { returns(T::Boolean) }
      def self.bidirectional_pagination; end

      # _@return_ — If true, connections check for reverse-direction `has*Page` values
      sig { params(value: T::Boolean).returns(T::Boolean) }
      def self.bidirectional_pagination=(value); end

      # Create a connection which exposes edges of this type
      sig do
        params(
          wrapped_type: T.untyped,
          edge_type: T.untyped,
          edge_class: T.untyped,
          nodes_field: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def self.create_type(wrapped_type, edge_type: nil, edge_class: GraphQL::Relay::Edge, nodes_field: ConnectionType.default_nodes_field, &block); end
    end

    # Mixin for Relay-related methods in type objects
    # (used by BaseType and Schema::Member).
    module TypeExtensions
      # _@return_ — The default connection type for this object type
      sig { returns(GraphQL::ObjectType) }
      def connection_type; end

      # Define a custom connection type for this object type
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
      def define_connection(**kwargs, &block); end

      # _@return_ — The default edge type for this object type
      sig { returns(GraphQL::ObjectType) }
      def edge_type; end

      # Define a custom edge type for this object type
      sig { params(kwargs: T.untyped, block: T.untyped).returns(GraphQL::ObjectType) }
      def define_edge(**kwargs, &block); end
    end

    class ArrayConnection < GraphQL::Relay::BaseConnection
      CURSOR_SEPARATOR = T.let("---", T.untyped)
      CONNECTION_IMPLEMENTATIONS = T.let({}, T.untyped)

      sig { params(item: T.untyped).returns(T.untyped) }
      def cursor_from_node(item); end

      sig { returns(T.untyped) }
      def has_next_page; end

      sig { returns(T.untyped) }
      def has_previous_page; end

      sig { returns(T.untyped) }
      def first; end

      sig { returns(T.untyped) }
      def last; end

      # apply first / last limit results
      sig { returns(T.untyped) }
      def paged_nodes; end

      # Apply cursors to edges
      sig { returns(T.untyped) }
      def sliced_nodes; end

      sig { params(cursor: T.untyped).returns(T.untyped) }
      def index_from_cursor(cursor); end
    end

    class GlobalIdResolve
      sig { params(type: T.untyped).returns(GlobalIdResolve) }
      def initialize(type:); end

      sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def call(obj, args, ctx); end
    end

    class ConnectionResolve
      sig { params(field: T.untyped, underlying_resolve: T.untyped).returns(ConnectionResolve) }
      def initialize(field, underlying_resolve); end

      sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def call(obj, args, ctx); end

      sig do
        params(
          nodes: T.untyped,
          args: T.untyped,
          parent: T.untyped,
          ctx: T.untyped
        ).returns(T.untyped)
      end
      def build_connection(nodes, args, parent, ctx); end
    end

    # A connection implementation to expose SQL collection objects.
    # It works for:
    # - `ActiveRecord::Relation`
    # - `Sequel::Dataset`
    class RelationConnection < GraphQL::Relay::BaseConnection
      CURSOR_SEPARATOR = T.let("---", T.untyped)
      CONNECTION_IMPLEMENTATIONS = T.let({}, T.untyped)

      sig { params(item: T.untyped).returns(T.untyped) }
      def cursor_from_node(item); end

      sig { returns(T.untyped) }
      def has_next_page; end

      sig { returns(T.untyped) }
      def has_previous_page; end

      sig { returns(T.untyped) }
      def first; end

      sig { returns(T.untyped) }
      def last; end

      # apply first / last limit results
      sig { returns(T::Array[T.untyped]) }
      def paged_nodes; end

      sig { returns(T.untyped) }
      def paged_nodes_offset; end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_offset(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_limit(relation); end

      # If a relation contains a `.group` clause, a `.count` will return a Hash.
      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_count(relation); end

      # Apply cursors to edges
      sig { returns(T.untyped) }
      def sliced_nodes; end

      sig { params(sliced_nodes: T.untyped, limit: T.untyped).returns(T.untyped) }
      def limit_nodes(sliced_nodes, limit); end

      sig { returns(T.untyped) }
      def sliced_nodes_count; end

      sig { params(cursor: T.untyped).returns(T.untyped) }
      def offset_from_cursor(cursor); end
    end

    module EdgesInstrumentation
      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def self.instrument(type, field); end

      class EdgesResolve
        sig { params(edge_class: T.untyped, resolve: T.untyped).returns(EdgesResolve) }
        def initialize(edge_class:, resolve:); end

        # A user's custom Connection may return a lazy object,
        # if so, handle it later.
        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def call(obj, args, ctx); end
      end
    end

    # A connection implementation to expose MongoDB collection objects.
    # It works for:
    # - `Mongoid::Criteria`
    class MongoRelationConnection < GraphQL::Relay::RelationConnection
      CURSOR_SEPARATOR = T.let("---", T.untyped)
      CONNECTION_IMPLEMENTATIONS = T.let({}, T.untyped)

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_offset(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_limit(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_count(relation); end

      sig { params(sliced_nodes: T.untyped, limit: T.untyped).returns(T.untyped) }
      def limit_nodes(sliced_nodes, limit); end
    end

    # Provided a GraphQL field which returns a collection of nodes,
    # wrap that field to expose those nodes as a connection.
    # 
    # The original resolve proc is used to fetch nodes,
    # then a connection implementation is fetched with {BaseConnection.connection_for_nodes}.
    module ConnectionInstrumentation
      sig { returns(T.untyped) }
      def self.default_arguments; end

      # Build a connection field from a {GraphQL::Field} by:
      # - Merging in the default arguments
      # - Transforming its resolve function to return a connection object
      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def self.instrument(type, field); end
    end
  end

  # Type kinds are the basic categories which a type may belong to (`Object`, `Scalar`, `Union`...)
  module TypeKinds
    TYPE_KINDS = T.let([
  SCALAR =        TypeKind.new("SCALAR", input: true, description: 'Indicates this type is a scalar.'),
  OBJECT =        TypeKind.new("OBJECT", fields: true, description: 'Indicates this type is an object. `fields` and `interfaces` are valid fields.'),
  INTERFACE =     TypeKind.new("INTERFACE", abstract: true, fields: true, description: 'Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.'),
  UNION =         TypeKind.new("UNION", abstract: true, description: 'Indicates this type is a union. `possibleTypes` is a valid field.'),
  ENUM =          TypeKind.new("ENUM", input: true, description: 'Indicates this type is an enum. `enumValues` is a valid field.'),
  INPUT_OBJECT =  TypeKind.new("INPUT_OBJECT", input: true, description: 'Indicates this type is an input object. `inputFields` is a valid field.'),
  LIST =          TypeKind.new("LIST", wraps: true, description: 'Indicates this type is a list. `ofType` is a valid field.'),
  NON_NULL =      TypeKind.new("NON_NULL", wraps: true, description: 'Indicates this type is a non-null. `ofType` is a valid field.'),
], T.untyped)

    # These objects are singletons, eg `GraphQL::TypeKinds::UNION`, `GraphQL::TypeKinds::SCALAR`.
    class TypeKind
      # Returns the value of attribute name
      sig { returns(T.untyped) }
      def name; end

      # Returns the value of attribute description
      sig { returns(T.untyped) }
      def description; end

      sig do
        params(
          name: T.untyped,
          abstract: T.untyped,
          fields: T.untyped,
          wraps: T.untyped,
          input: T.untyped,
          description: T.untyped
        ).returns(TypeKind)
      end
      def initialize(name, abstract: false, fields: false, wraps: false, input: false, description: nil); end

      # Does this TypeKind have multiple possible implementors?
      # 
      # _@deprecated_ — Use `abstract?` instead of `resolves?`.
      sig { returns(T::Boolean) }
      def resolves?; end

      # Is this TypeKind abstract?
      sig { returns(T::Boolean) }
      def abstract?; end

      # Does this TypeKind have queryable fields?
      sig { returns(T::Boolean) }
      def fields?; end

      # Does this TypeKind modify another type?
      sig { returns(T::Boolean) }
      def wraps?; end

      # Is this TypeKind a valid query input?
      sig { returns(T::Boolean) }
      def input?; end

      sig { returns(T.untyped) }
      def to_s; end

      # Is this TypeKind composed of many values?
      sig { returns(T::Boolean) }
      def composite?; end

      sig { returns(T::Boolean) }
      def scalar?; end

      sig { returns(T::Boolean) }
      def object?; end

      sig { returns(T::Boolean) }
      def interface?; end

      sig { returns(T::Boolean) }
      def union?; end

      sig { returns(T::Boolean) }
      def enum?; end

      sig { returns(T::Boolean) }
      def input_object?; end

      sig { returns(T::Boolean) }
      def list?; end

      sig { returns(T::Boolean) }
      def non_null?; end
    end
  end

  # A Union is is a collection of object types which may appear in the same place.
  # 
  # The members of a union are declared with `possible_types`.
  # 
  # @example A union of object types
  #   MediaUnion = GraphQL::UnionType.define do
  #     name "Media"
  #     description "Media objects which you can enjoy"
  #     possible_types [AudioType, ImageType, VideoType]
  #   end
  # 
  # A union itself has no fields; only its members have fields.
  # So, when you query, you must use fragment spreads to access fields.
  # 
  # @example Querying for fields on union members
  #  {
  #    searchMedia(name: "Jens Lekman") {
  #      ... on Audio { name, duration }
  #      ... on Image { name, height, width }
  #      ... on Video { name, length, quality }
  #    }
  #  }
  class UnionType < GraphQL::BaseType
    # Returns the value of attribute resolve_type_proc
    sig { returns(T.untyped) }
    def resolve_type_proc; end

    # Sets the attribute resolve_type_proc
    # 
    # _@param_ `value` — the value to set the attribute resolve_type_proc to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def resolve_type_proc=(value); end

    sig { returns(UnionType) }
    def initialize; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    sig { returns(T.untyped) }
    def kind; end

    # _@return_ — True if `child_type_defn` is a member of this {UnionType}
    sig { params(child_type_defn: T.untyped).returns(T::Boolean) }
    def include?(child_type_defn); end

    sig { params(new_possible_types: T::Array[GraphQL::ObjectType]).returns(T.untyped) }
    def possible_types=(new_possible_types); end

    # _@return_ — Types which may be found in this union
    sig { returns(T::Array[GraphQL::ObjectType]) }
    def possible_types; end

    # Get a possible type of this {UnionType} by type name
    # 
    # _@param_ `type_name` — 
    # 
    # _@param_ `ctx` — The context for the current query
    # 
    # _@return_ — The type named `type_name` if it exists and is a member of this {UnionType}, (else `nil`)
    sig { params(type_name: String, ctx: GraphQL::Query::Context).returns(T.nilable(GraphQL::ObjectType)) }
    def get_possible_type(type_name, ctx); end

    # Check if a type is a possible type of this {UnionType}
    # 
    # _@param_ `type` — Name of the type or a type definition
    # 
    # _@param_ `ctx` — The context for the current query
    # 
    # _@return_ — True if the `type` exists and is a member of this {UnionType}, (else `nil`)
    sig { params(type: T.any(String, GraphQL::BaseType), ctx: GraphQL::Query::Context).returns(T::Boolean) }
    def possible_type?(type, ctx); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def resolve_type(value, ctx); end

    sig { params(new_resolve_type_proc: T.untyped).returns(T.untyped) }
    def resolve_type=(new_resolve_type_proc); end

    # Returns the value of attribute dirty_possible_types
    sig { returns(T.untyped) }
    def dirty_possible_types; end
  end

  # This type exposes fields on an object.
  # 
  # @example defining a type for your IMDB clone
  #   MovieType = GraphQL::ObjectType.define do
  #     name "Movie"
  #     description "A full-length film or a short film"
  #     interfaces [ProductionInterface, DurationInterface]
  # 
  #     field :runtimeMinutes, !types.Int, property: :runtime_minutes
  #     field :director, PersonType
  #     field :cast, CastType
  #     field :starring, types[PersonType] do
  #       argument :limit, types.Int
  #       resolve ->(object, args, ctx) {
  #         stars = object.cast.stars
  #         args[:limit] && stars = stars.limit(args[:limit])
  #         stars
  #       }
  #      end
  #   end
  class ObjectType < GraphQL::BaseType
    # _@return_ — Map String fieldnames to their {GraphQL::Field} implementations
    sig { returns(T::Hash[String, GraphQL::Field]) }
    def fields; end

    # _@return_ — Map String fieldnames to their {GraphQL::Field} implementations
    sig { params(value: T::Hash[String, GraphQL::Field]).returns(T::Hash[String, GraphQL::Field]) }
    def fields=(value); end

    # _@return_ — The mutation this object type was derived from, if it is an auto-generated payload type.
    sig { returns(T.nilable(GraphQL::Relay::Mutation)) }
    def mutation; end

    # _@return_ — The mutation this object type was derived from, if it is an auto-generated payload type.
    sig { params(value: T.nilable(GraphQL::Relay::Mutation)).returns(T.nilable(GraphQL::Relay::Mutation)) }
    def mutation=(value); end

    # Returns the value of attribute relay_node_type
    sig { returns(T.untyped) }
    def relay_node_type; end

    # Sets the attribute relay_node_type
    # 
    # _@param_ `value` — the value to set the attribute relay_node_type to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def relay_node_type=(value); end

    sig { returns(ObjectType) }
    def initialize; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    # This method declares interfaces for this type AND inherits any field definitions
    # 
    # _@param_ `new_interfaces` — interfaces that this type implements
    # 
    # _@deprecated_ — Use `implements` instead of `interfaces`.
    sig { params(new_interfaces: T::Array[T.untyped]).returns(T.untyped) }
    def interfaces=(new_interfaces); end

    sig { returns(T.untyped) }
    def interfaces; end

    sig { returns(T.untyped) }
    def kind; end

    # This fields doesnt have instrumenation applied
    # 
    # _@return_ — The field definition for `field_name` (may be inherited from interfaces)
    # 
    # _@see_ `[Schema#get_field]` — Get field with instrumentation
    sig { params(field_name: T.untyped).returns(GraphQL::Field) }
    def get_field(field_name); end

    # These fields don't have instrumenation applied
    # 
    # _@return_ — All fields, including ones inherited from interfaces
    # 
    # _@see_ `[Schema#get_fields]` — Get fields with instrumentation
    sig { returns(T::Array[GraphQL::Field]) }
    def all_fields; end

    # Declare that this object implements this interface.
    # This declaration will be validated when the schema is defined.
    # 
    # _@param_ `interfaces` — add a new interface that this type implements
    # 
    # _@param_ `inherits` — If true, copy the interfaces' field definitions to this type
    sig { params(interfaces: T::Array[T.untyped], inherit: T.untyped).returns(T.untyped) }
    def implements(interfaces, inherit: false); end

    sig { returns(T.untyped) }
    def resolve_type_proc; end

    # Returns the value of attribute dirty_interfaces
    sig { returns(T.untyped) }
    def dirty_interfaces; end

    # Returns the value of attribute dirty_inherited_interfaces
    sig { returns(T.untyped) }
    def dirty_inherited_interfaces; end

    sig { params(ifaces: T.untyped).returns(T.untyped) }
    def normalize_interfaces(ifaces); end

    sig { returns(T.untyped) }
    def interface_fields; end

    sig { returns(T.untyped) }
    def load_interfaces; end
  end

  class ParseError < GraphQL::Error
    # Returns the value of attribute line
    sig { returns(T.untyped) }
    def line; end

    # Returns the value of attribute col
    sig { returns(T.untyped) }
    def col; end

    # Returns the value of attribute query
    sig { returns(T.untyped) }
    def query; end

    sig do
      params(
        message: T.untyped,
        line: T.untyped,
        col: T.untyped,
        query: T.untyped,
        filename: T.untyped
      ).returns(ParseError)
    end
    def initialize(message, line, col, query, filename: nil); end

    sig { returns(T.untyped) }
    def to_h; end
  end

  # # GraphQL::ScalarType
  # 
  # Scalars are plain values. They are leaf nodes in a GraphQL query tree.
  # 
  # ## Built-in Scalars
  # 
  # `GraphQL` comes with standard built-in scalars:
  # 
  # |Constant | `.define` helper|
  # |-------|--------|
  # |`GraphQL::STRING_TYPE` | `types.String`|
  # |`GraphQL::INT_TYPE` | `types.Int`|
  # |`GraphQL::FLOAT_TYPE` | `types.Float`|
  # |`GraphQL::ID_TYPE` | `types.ID`|
  # |`GraphQL::BOOLEAN_TYPE` | `types.Boolean`|
  # 
  # (`types` is an instance of `GraphQL::Definition::TypeDefiner`; `.String`, `.Float`, etc are methods which return built-in scalars.)
  # 
  # ## Custom Scalars
  # 
  # You can define custom scalars for your GraphQL server. It requires some special functions:
  # 
  # - `coerce_input` is used to prepare incoming values for GraphQL execution. (Incoming values come from variables or literal values in the query string.)
  # - `coerce_result` is used to turn Ruby values _back_ into serializable values for query responses.
  # 
  # @example defining a type for Time
  #   TimeType = GraphQL::ScalarType.define do
  #     name "Time"
  #     description "Time since epoch in seconds"
  # 
  #     coerce_input ->(value, ctx) { Time.at(Float(value)) }
  #     coerce_result ->(value, ctx) { value.to_f }
  #   end
  # 
  # 
  # You can customize the error message for invalid input values by raising a `GraphQL::CoercionError` within `coerce_input`:
  # 
  # @example raising a custom error message
  #   TimeType = GraphQL::ScalarType.define do
  #     name "Time"
  #     description "Time since epoch in seconds"
  # 
  #     coerce_input ->(value, ctx) do
  #       begin
  #         Time.at(Float(value))
  #       rescue ArgumentError
  #         raise GraphQL::CoercionError, "cannot coerce `#{value.inspect}` to Float"
  #       end
  #     end
  # 
  #     coerce_result ->(value, ctx) { value.to_f }
  #   end
  # 
  # This will result in the message of the `GraphQL::CoercionError` being used in the error response:
  # 
  # @example custom error response
  #   {"message"=>"cannot coerce `"2"` to Float", "locations"=>[{"line"=>3, "column"=>9}], "fields"=>["arg"]}
  class ScalarType < GraphQL::BaseType
    sig { returns(ScalarType) }
    def initialize; end

    sig { params(proc: T.untyped).returns(T.untyped) }
    def coerce=(proc); end

    sig { params(coerce_input_fn: T.untyped).returns(T.untyped) }
    def coerce_input=(coerce_input_fn); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_result(value, ctx = nil); end

    sig { params(coerce_result_fn: T.untyped).returns(T.untyped) }
    def coerce_result=(coerce_result_fn); end

    sig { returns(T.untyped) }
    def kind; end

    sig { params(callable: T.untyped, method_name: T.untyped).returns(T.untyped) }
    def ensure_two_arg(callable, method_name); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_non_null_input(value, ctx); end

    sig { params(value: T.untyped).returns(T.untyped) }
    def raw_coercion_input(value); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def validate_non_null_input(value, ctx); end

    module NoOpCoerce
      sig { params(val: T.untyped, ctx: T.untyped).returns(T.untyped) }
      def self.call(val, ctx); end
    end
  end

  module Analysis
    sig { params(multiplex: T.untyped, analyzers: T.untyped).void }
    def analyze_multiplex(multiplex, analyzers); end

    sig { params(multiplex: T.untyped, analyzers: T.untyped).void }
    def self.analyze_multiplex(multiplex, analyzers); end

    # Visit `query`'s internal representation, calling `analyzers` along the way.
    # 
    # - First, query analyzers are filtered down by calling `.analyze?(query)`, if they respond to that method
    # - Then, query analyzers are initialized by calling `.initial_value(query)`, if they respond to that method.
    # - Then, they receive `.call(memo, visit_type, irep_node)`, where visit type is `:enter` or `:leave`.
    # - Last, they receive `.final_value(memo)`, if they respond to that method.
    # 
    # It returns an array of final `memo` values in the order that `analyzers` were passed in.
    # 
    # _@param_ `query`
    # 
    # _@param_ `analyzers` — Objects that respond to `#call(memo, visit_type, irep_node)`
    # 
    # _@return_ — Results from those analyzers
    sig { params(query: GraphQL::Query, analyzers: T::Array[T.untyped], multiplex_states: T.untyped).returns(T::Array[T.untyped]) }
    def analyze_query(query, analyzers, multiplex_states: []); end

    # Visit `query`'s internal representation, calling `analyzers` along the way.
    # 
    # - First, query analyzers are filtered down by calling `.analyze?(query)`, if they respond to that method
    # - Then, query analyzers are initialized by calling `.initial_value(query)`, if they respond to that method.
    # - Then, they receive `.call(memo, visit_type, irep_node)`, where visit type is `:enter` or `:leave`.
    # - Last, they receive `.final_value(memo)`, if they respond to that method.
    # 
    # It returns an array of final `memo` values in the order that `analyzers` were passed in.
    # 
    # _@param_ `query` — 
    # 
    # _@param_ `analyzers` — Objects that respond to `#call(memo, visit_type, irep_node)`
    # 
    # _@return_ — Results from those analyzers
    sig { params(query: GraphQL::Query, analyzers: T::Array[T.untyped], multiplex_states: T.untyped).returns(T::Array[T.untyped]) }
    def self.analyze_query(query, analyzers, multiplex_states: []); end

    # Enter the node, visit its children, then leave the node.
    sig { params(irep_node: T.untyped, reducer_states: T.untyped).returns(T.untyped) }
    def reduce_node(irep_node, reducer_states); end

    # Enter the node, visit its children, then leave the node.
    sig { params(irep_node: T.untyped, reducer_states: T.untyped).returns(T.untyped) }
    def self.reduce_node(irep_node, reducer_states); end

    sig { params(visit_type: T.untyped, irep_node: T.untyped, reducer_states: T.untyped).returns(T.untyped) }
    def visit_analyzers(visit_type, irep_node, reducer_states); end

    sig { params(visit_type: T.untyped, irep_node: T.untyped, reducer_states: T.untyped).returns(T.untyped) }
    def self.visit_analyzers(visit_type, irep_node, reducer_states); end

    sig { params(results: T.untyped).returns(T.untyped) }
    def analysis_errors(results); end

    sig { params(results: T.untyped).returns(T.untyped) }
    def self.analysis_errors(results); end

    # Calculate the complexity of a query, using {Field#complexity} values.
    module AST
      sig { params(schema_defn: T.untyped).returns(T.untyped) }
      def use(schema_defn); end

      sig { params(schema_defn: T.untyped).returns(T.untyped) }
      def self.use(schema_defn); end

      # Analyze a multiplex, and all queries within.
      # Multiplex analyzers are ran for all queries, keeping state.
      # Query analyzers are ran per query, without carrying state between queries.
      # 
      # _@param_ `multiplex`
      # 
      # _@param_ `analyzers`
      sig { params(multiplex: GraphQL::Execution::Multiplex, analyzers: T::Array[GraphQL::Analysis::AST::Analyzer]).void }
      def analyze_multiplex(multiplex, analyzers); end

      # Analyze a multiplex, and all queries within.
      # Multiplex analyzers are ran for all queries, keeping state.
      # Query analyzers are ran per query, without carrying state between queries.
      # 
      # _@param_ `multiplex` — 
      # 
      # _@param_ `analyzers` — 
      sig { params(multiplex: GraphQL::Execution::Multiplex, analyzers: T::Array[GraphQL::Analysis::AST::Analyzer]).void }
      def self.analyze_multiplex(multiplex, analyzers); end

      # _@param_ `query`
      # 
      # _@param_ `analyzers`
      # 
      # _@return_ — Results from those analyzers
      sig { params(query: GraphQL::Query, analyzers: T::Array[GraphQL::Analysis::AST::Analyzer], multiplex_analyzers: T.untyped).returns(T::Array[T.untyped]) }
      def analyze_query(query, analyzers, multiplex_analyzers: []); end

      # _@param_ `query` — 
      # 
      # _@param_ `analyzers` — 
      # 
      # _@return_ — Results from those analyzers
      sig { params(query: GraphQL::Query, analyzers: T::Array[GraphQL::Analysis::AST::Analyzer], multiplex_analyzers: T.untyped).returns(T::Array[T.untyped]) }
      def self.analyze_query(query, analyzers, multiplex_analyzers: []); end

      sig { params(results: T.untyped).returns(T.untyped) }
      def analysis_errors(results); end

      sig { params(results: T.untyped).returns(T.untyped) }
      def self.analysis_errors(results); end

      # Depth first traversal through a query AST, calling AST analyzers
      # along the way.
      # 
      # The visitor is a special case of GraphQL::Language::Visitor, visiting
      # only the selected operation, providing helpers for common use cases such
      # as skipped fields and visiting fragment spreads.
      # 
      # @see {GraphQL::Analysis::AST::Analyzer} AST Analyzers for queries
      class Visitor < GraphQL::Language::Visitor
        SKIP = T.let(:_skip, T.untyped)
        DELETE_NODE = T.let(DeleteNode.new, T.untyped)

        sig { params(query: T.untyped, analyzers: T.untyped).returns(Visitor) }
        def initialize(query:, analyzers:); end

        # _@return_ — the query being visited
        sig { returns(GraphQL::Query) }
        def query; end

        # _@return_ — Types whose scope we've entered
        sig { returns(T::Array[GraphQL::ObjectType]) }
        def object_types; end

        sig { returns(T.untyped) }
        def visit; end

        # _@return_ — Arguments for this node, merging default values, literal values and query variables
        # 
        # _@see_ `{GraphQL::Query#arguments_for}`
        sig { params(ast_node: T.untyped, field_definition: T.untyped).returns(GraphQL::Query::Arguments) }
        def arguments_for(ast_node, field_definition); end

        # _@return_ — If the visitor is currently inside a fragment definition
        sig { returns(T::Boolean) }
        def visiting_fragment_definition?; end

        # _@return_ — If the current node should be skipped because of a skip or include directive
        sig { returns(T::Boolean) }
        def skipping?; end

        # _@return_ — The path to the response key for the current field
        sig { returns(T::Array[String]) }
        def response_path; end

        # Visitor Hooks
        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_operation_definition(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_fragment_definition(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_inline_fragment(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_field(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_directive(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_argument(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_fragment_spread(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_abstract_node(node, parent); end

        # _@return_ — The current object type
        sig { returns(GraphQL::BaseType) }
        def type_definition; end

        # _@return_ — The type which the current type came from
        sig { returns(GraphQL::BaseType) }
        def parent_type_definition; end

        # _@return_ — The most-recently-entered GraphQL::Field, if currently inside one
        sig { returns(T.nilable(GraphQL::Field)) }
        def field_definition; end

        # _@return_ — The GraphQL field which returned the object that the current field belongs to
        sig { returns(T.nilable(GraphQL::Field)) }
        def previous_field_definition; end

        # _@return_ — The most-recently-entered GraphQL::Directive, if currently inside one
        sig { returns(T.nilable(GraphQL::Directive)) }
        def directive_definition; end

        # _@return_ — The most-recently-entered GraphQL::Argument, if currently inside one
        sig { returns(T.nilable(GraphQL::Argument)) }
        def argument_definition; end

        # _@return_ — The previous GraphQL argument
        sig { returns(T.nilable(GraphQL::Argument)) }
        def previous_argument_definition; end

        # Visit a fragment spread inline instead of visiting the definition
        # by itself.
        sig { params(fragment_spread: T.untyped).returns(T.untyped) }
        def enter_fragment_spread_inline(fragment_spread); end

        # Visit a fragment spread inline instead of visiting the definition
        # by itself.
        sig { params(_fragment_spread: T.untyped).returns(T.untyped) }
        def leave_fragment_spread_inline(_fragment_spread); end

        sig { params(ast_node: T.untyped).returns(T::Boolean) }
        def skip?(ast_node); end

        sig { params(method: T.untyped, node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def call_analyzers(method, node, parent); end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_fragment_with_type(node); end
      end

      # Query analyzer for query ASTs. Query analyzers respond to visitor style methods
      # but are prefixed by `enter` and `leave`.
      # 
      # @param [GraphQL::Query] The query to analyze
      class Analyzer
        sig { params(query: T.untyped).returns(Analyzer) }
        def initialize(query); end

        # Analyzer hook to decide at analysis time whether a query should
        # be analyzed or not.
        # 
        # _@return_ — If the query should be analyzed or not
        sig { returns(T::Boolean) }
        def analyze?; end

        # The result for this analyzer. Returning {GraphQL::AnalysisError} results
        # in a query error.
        # 
        # _@return_ — The analyzer result
        sig { returns(T.untyped) }
        def result; end

        sig { params(member_name: T.untyped).returns(T.untyped) }
        def self.build_visitor_hooks(member_name); end

        # Returns the value of attribute query
        sig { returns(T.untyped) }
        def query; end
      end

      class FieldUsage < GraphQL::Analysis::AST::Analyzer
        sig { params(query: T.untyped).returns(FieldUsage) }
        def initialize(query); end

        sig { params(node: T.untyped, parent: T.untyped, visitor: T.untyped).returns(T.untyped) }
        def on_leave_field(node, parent, visitor); end

        sig { returns(T.untyped) }
        def result; end
      end

      class QueryDepth < GraphQL::Analysis::AST::Analyzer
        sig { params(query: T.untyped).returns(QueryDepth) }
        def initialize(query); end

        sig { params(node: T.untyped, parent: T.untyped, visitor: T.untyped).returns(T.untyped) }
        def on_enter_field(node, parent, visitor); end

        sig { params(node: T.untyped, parent: T.untyped, visitor: T.untyped).returns(T.untyped) }
        def on_leave_field(node, parent, visitor); end

        sig { returns(T.untyped) }
        def result; end
      end

      class MaxQueryDepth < GraphQL::Analysis::AST::QueryDepth
        sig { returns(T.untyped) }
        def result; end
      end

      class QueryComplexity < GraphQL::Analysis::AST::Analyzer
        # State for the query complexity calculation:
        # - `complexities_on_type` holds complexity scores for each type in an IRep node
        sig { params(query: T.untyped).returns(QueryComplexity) }
        def initialize(query); end

        # Overide this method to use the complexity result
        sig { returns(T.untyped) }
        def result; end

        sig { params(node: T.untyped, parent: T.untyped, visitor: T.untyped).returns(T.untyped) }
        def on_enter_field(node, parent, visitor); end

        sig { params(node: T.untyped, parent: T.untyped, visitor: T.untyped).returns(T.untyped) }
        def on_leave_field(node, parent, visitor); end

        sig { returns(Integer) }
        def max_possible_complexity; end

        sig { params(response_path: T.untyped, query: T.untyped).returns(T.untyped) }
        def selection_key(response_path, query); end

        # Get a complexity value for a field,
        # by getting the number or calling its proc
        sig do
          params(
            ast_node: T.untyped,
            field_defn: T.untyped,
            child_complexity: T.untyped,
            visitor: T.untyped
          ).returns(T.untyped)
        end
        def get_complexity(ast_node, field_defn, child_complexity, visitor); end

        # Selections on an object may apply differently depending on what is _actually_ returned by the resolve function.
        # Find the maximum possible complexity among those combinations.
        class AbstractTypeComplexity
          sig { returns(AbstractTypeComplexity) }
          def initialize; end

          # Return the max possible complexity for types in this selection
          sig { returns(T.untyped) }
          def max_possible_complexity; end

          # Store the complexity for the branch on `type_defn`.
          # Later we will see if this is the max complexity among branches.
          sig { params(type_defn: T.untyped, key: T.untyped, complexity: T.untyped).returns(T.untyped) }
          def merge(type_defn, key, complexity); end
        end

        class ConcreteTypeComplexity
          # Returns the value of attribute max_possible_complexity
          sig { returns(T.untyped) }
          def max_possible_complexity; end

          sig { returns(ConcreteTypeComplexity) }
          def initialize; end

          sig { params(complexity: T.untyped).returns(T.untyped) }
          def merge(complexity); end
        end
      end

      # Used under the hood to implement complexity validation,
      # see {Schema#max_complexity} and {Query#max_complexity}
      class MaxQueryComplexity < GraphQL::Analysis::AST::QueryComplexity
        sig { returns(T.untyped) }
        def result; end
      end
    end

    # A query reducer for tracking both field usage and deprecated field usage.
    # 
    # @example Logging field usage and deprecated field usage
    #   Schema.query_analyzers << GraphQL::Analysis::FieldUsage.new { |query, used_fields, used_deprecated_fields|
    #     puts "Used GraphQL fields: #{used_fields.join(', ')}"
    #     puts "Used deprecated GraphQL fields: #{used_deprecated_fields.join(', ')}"
    #   }
    #   Schema.execute(query_str)
    #   # Used GraphQL fields: Cheese.id, Cheese.fatContent, Query.cheese
    #   # Used deprecated GraphQL fields: Cheese.fatContent
    class FieldUsage
      sig { params(block: T.untyped).returns(FieldUsage) }
      def initialize(&block); end

      sig { params(query: T.untyped).returns(T.untyped) }
      def initial_value(query); end

      sig { params(memo: T.untyped, visit_type: T.untyped, irep_node: T.untyped).returns(T.untyped) }
      def call(memo, visit_type, irep_node); end

      sig { params(memo: T.untyped).returns(T.untyped) }
      def final_value(memo); end
    end

    # A query reducer for measuring the depth of a given query.
    # 
    # @example Logging the depth of a query
    #   Schema.query_analyzers << GraphQL::Analysis::QueryDepth.new { |query, depth|  puts "GraphQL query depth: #{depth}" }
    #   Schema.execute(query_str)
    #   # GraphQL query depth: 8
    class QueryDepth
      sig { params(block: T.untyped).returns(QueryDepth) }
      def initialize(&block); end

      sig { params(query: T.untyped).returns(T.untyped) }
      def initial_value(query); end

      sig { params(memo: T.untyped, visit_type: T.untyped, irep_node: T.untyped).returns(T.untyped) }
      def call(memo, visit_type, irep_node); end

      sig { params(memo: T.untyped).returns(T.untyped) }
      def final_value(memo); end
    end

    class ReducerState
      # Returns the value of attribute reducer
      sig { returns(T.untyped) }
      def reducer; end

      # Returns the value of attribute memo
      sig { returns(T.untyped) }
      def memo; end

      # Sets the attribute memo
      # 
      # _@param_ `value` — the value to set the attribute memo to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def memo=(value); end

      # Returns the value of attribute errors
      sig { returns(T.untyped) }
      def errors; end

      # Sets the attribute errors
      # 
      # _@param_ `value` — the value to set the attribute errors to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def errors=(value); end

      sig { params(reducer: T.untyped, query: T.untyped).returns(ReducerState) }
      def initialize(reducer, query); end

      sig { params(visit_type: T.untyped, irep_node: T.untyped).returns(T.untyped) }
      def call(visit_type, irep_node); end

      # Respond with any errors, if found. Otherwise, if the reducer accepts
      # `final_value`, send it the last memo value.
      # Otherwise, use the last value from the traversal.
      # 
      # _@return_ — final memo value
      sig { returns(T.untyped) }
      def finalize_reducer; end

      # If the reducer has an `initial_value` method, call it and store
      # the result as `memo`. Otherwise, use `nil` as memo.
      # 
      # _@return_ — initial memo value
      sig { params(reducer: T.untyped, query: T.untyped).returns(T.untyped) }
      def initialize_reducer(reducer, query); end
    end

    # Used under the hood to implement depth validation,
    # see {Schema#max_depth} and {Query#max_depth}
    # 
    # @example Assert max depth of 10
    #   # DON'T actually do this, graphql-ruby
    #   # Does this for you based on your `max_depth` setting
    #   MySchema.query_analyzers << GraphQL::Analysis::MaxQueryDepth.new(10)
    class MaxQueryDepth < GraphQL::Analysis::QueryDepth
      sig { params(max_depth: T.untyped).returns(MaxQueryDepth) }
      def initialize(max_depth); end
    end

    # Calculate the complexity of a query, using {Field#complexity} values.
    # 
    # @example Log the complexity of incoming queries
    #   MySchema.query_analyzers << GraphQL::Analysis::QueryComplexity.new do |query, complexity|
    #     Rails.logger.info("Complexity: #{complexity}")
    #   end
    class QueryComplexity
      sig { params(block: T.proc.params(query: GraphQL::Query, complexity: Numeric).void).returns(QueryComplexity) }
      def initialize(&block); end

      # State for the query complexity calcuation:
      # - `target` is passed to handler
      # - `complexities_on_type` holds complexity scores for each type in an IRep node
      sig { params(target: T.untyped).returns(T.untyped) }
      def initial_value(target); end

      # Implement the query analyzer API
      sig { params(memo: T.untyped, visit_type: T.untyped, irep_node: T.untyped).returns(T.untyped) }
      def call(memo, visit_type, irep_node); end

      # Send the query and complexity to the block
      # 
      # _@return_ — Whatever the handler returns
      sig { params(reduced_value: T.untyped).returns(T.any(Object, GraphQL::AnalysisError)) }
      def final_value(reduced_value); end

      # Get a complexity value for a field,
      # by getting the number or calling its proc
      sig { params(irep_node: T.untyped, child_complexity: T.untyped).returns(T.untyped) }
      def get_complexity(irep_node, child_complexity); end

      # Selections on an object may apply differently depending on what is _actually_ returned by the resolve function.
      # Find the maximum possible complexity among those combinations.
      class TypeComplexity
        sig { returns(TypeComplexity) }
        def initialize; end

        # Return the max possible complexity for types in this selection
        sig { returns(T.untyped) }
        def max_possible_complexity; end

        # Store the complexity for the branch on `type_defn`.
        # Later we will see if this is the max complexity among branches.
        sig { params(type_defn: T.untyped, complexity: T.untyped).returns(T.untyped) }
        def merge(type_defn, complexity); end
      end
    end

    # Used under the hood to implement complexity validation,
    # see {Schema#max_complexity} and {Query#max_complexity}
    # 
    # @example Assert max complexity of 10
    #   # DON'T actually do this, graphql-ruby
    #   # Does this for you based on your `max_complexity` setting
    #   MySchema.query_analyzers << GraphQL::Analysis::MaxQueryComplexity.new(10)
    class MaxQueryComplexity < GraphQL::Analysis::QueryComplexity
      sig { params(max_complexity: T.untyped).returns(MaxQueryComplexity) }
      def initialize(max_complexity); end
    end
  end

  module Authorization
    class InaccessibleFieldsError < GraphQL::AnalysisError
      # _@return_ — Fields that failed `.accessible?` checks
      sig { returns(T::Array[T.any(Schema::Field, GraphQL::Field)]) }
      def fields; end

      # _@return_ — The current query's context
      sig { returns(GraphQL::Query::Context) }
      def context; end

      # _@return_ — The visited nodes that failed `.accessible?` checks
      # 
      # _@see_ `{#fields}` — for the Field definitions
      sig { returns(T::Array[GraphQL::InternalRepresentation::Node]) }
      def irep_nodes; end

      sig { params(fields: T.untyped, irep_nodes: T.untyped, context: T.untyped).returns(InaccessibleFieldsError) }
      def initialize(fields:, irep_nodes:, context:); end
    end

    # @deprecated authorization at query runtime is generally a better idea.
    module Analyzer
      sig { params(query: T.untyped).returns(T.untyped) }
      def initial_value(query); end

      sig { params(query: T.untyped).returns(T.untyped) }
      def self.initial_value(query); end

      sig { params(memo: T.untyped, visit_type: T.untyped, irep_node: T.untyped).returns(T.untyped) }
      def call(memo, visit_type, irep_node); end

      sig { params(memo: T.untyped, visit_type: T.untyped, irep_node: T.untyped).returns(T.untyped) }
      def self.call(memo, visit_type, irep_node); end

      sig { params(memo: T.untyped).returns(T.untyped) }
      def final_value(memo); end

      sig { params(memo: T.untyped).returns(T.untyped) }
      def self.final_value(memo); end
    end
  end

  module Introspection
    INTROSPECTION_QUERY = T.let("
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args {
        ...InputValue
      }
    }
  }
}
fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}
fragment InputValue on __InputValue {
  name
  description
  type { ...TypeRef }
  defaultValue
}
fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
", T.untyped)

    class TypeType < GraphQL::Introspection::BaseObject
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def name; end

      sig { returns(T.untyped) }
      def kind; end

      sig { params(include_deprecated: T.untyped).returns(T.untyped) }
      def enum_values(include_deprecated:); end

      sig { returns(T.untyped) }
      def interfaces; end

      sig { returns(T.untyped) }
      def input_fields; end

      sig { returns(T.untyped) }
      def possible_types; end

      sig { params(include_deprecated: T.untyped).returns(T.untyped) }
      def fields(include_deprecated:); end

      sig { returns(T.untyped) }
      def of_type; end
    end

    class FieldType < GraphQL::Introspection::BaseObject
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def is_deprecated; end

      sig { returns(T.untyped) }
      def args; end
    end

    class BaseObject < GraphQL::Schema::Object
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { params(args: T.untyped, kwargs: T.untyped, block: T.untyped).returns(T.untyped) }
      def self.field(*args, **kwargs, &block); end

      sig { params(child_class: T.untyped).returns(T.untyped) }
      def self.inherited(child_class); end
    end

    class SchemaType < GraphQL::Introspection::BaseObject
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def types; end

      sig { returns(T.untyped) }
      def query_type; end

      sig { returns(T.untyped) }
      def mutation_type; end

      sig { returns(T.untyped) }
      def subscription_type; end

      sig { returns(T.untyped) }
      def directives; end

      sig { params(op_type: T.untyped).returns(T.untyped) }
      def permitted_root_type(op_type); end
    end

    class EntryPoints < GraphQL::Introspection::BaseObject
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def __schema; end

      sig { params(name: T.untyped).returns(T.untyped) }
      def __type(name:); end
    end

    class DirectiveType < GraphQL::Introspection::BaseObject
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def args; end
    end

    class DynamicFields < GraphQL::Introspection::BaseObject
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      # `irep_node:` will be nil for the interpreter, since there is no such thing
      sig { params(irep_node: T.untyped).returns(T.untyped) }
      def __typename(irep_node: nil); end
    end

    class TypeKindEnum < GraphQL::Schema::Enum
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)
    end

    class EnumValueType < GraphQL::Introspection::BaseObject
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def name; end

      sig { returns(T.untyped) }
      def is_deprecated; end
    end

    class InputValueType < GraphQL::Introspection::BaseObject
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)

      sig { returns(T.untyped) }
      def default_value; end

      # Recursively serialize, taking care not to add quotes to enum values
      sig { params(value: T.untyped, type: T.untyped).returns(T.untyped) }
      def serialize_default_value(value, type); end
    end

    class DirectiveLocationEnum < GraphQL::Schema::Enum
      Boolean = T.let("Boolean", T.untyped)
      ID = T.let("ID", T.untyped)
      Int = T.let("Int", T.untyped)
    end
  end

  # A non-null type modifies another type.
  # 
  # Non-null types can be created with `!` (`InnerType!`)
  # or {BaseType#to_non_null_type} (`InnerType.to_non_null_type`)
  # 
  # For return types, it says that the returned value will _always_ be present.
  # 
  # @example A field which _always_ returns an error
  #   field :items, !ItemType
  #   # or
  #   field :items, ItemType.to_non_null_type
  # 
  # (If the application fails to return a value, {InvalidNullError} will be passed to {Schema#type_error}.)
  # 
  # For input types, it says that the incoming value _must_ be provided by the query.
  # 
  # @example A field which _requires_ a string input
  #   field :newNames do
  #     # ...
  #     argument :values, !types.String
  #     # or
  #     argument :values, types.String.to_non_null_type
  #   end
  # 
  # (If a value isn't provided, {Query::VariableValidationError} will be raised).
  # 
  # Given a non-null type, you can always get the underlying type with {#unwrap}.
  class NonNullType < GraphQL::BaseType
    include GraphQL::BaseType::ModifiesAnotherType
    extend Forwardable

    # Returns the value of attribute of_type
    sig { returns(T.untyped) }
    def of_type; end

    sig { params(of_type: T.untyped).returns(NonNullType) }
    def initialize(of_type:); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T::Boolean) }
    def valid_input?(value, ctx); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def validate_input(value, ctx); end

    sig { returns(T.untyped) }
    def kind; end

    sig { returns(T.untyped) }
    def to_s; end

    sig { returns(T::Boolean) }
    def non_null?; end

    sig { returns(T.untyped) }
    def unwrap; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def ==(other); end
  end

  class Subscriptions
    # 
    # _@see_ `{Subscriptions#initialize}` — for options, concrete implementations may add options.
    sig { params(defn: T.untyped, options: T.untyped).returns(T.untyped) }
    def self.use(defn, options = {}); end

    # _@param_ `schema` — the GraphQL schema this manager belongs to
    sig { params(schema: Class, rest: T.untyped).returns(Subscriptions) }
    def initialize(schema:, **rest); end

    # Fetch subscriptions matching this field + arguments pair
    # And pass them off to the queue.
    # 
    # _@param_ `event_name` — 
    # 
    # _@param_ `args` — rgs [Hash<String, Symbol => Object]
    # 
    # _@param_ `object` — 
    # 
    # _@param_ `scope` — 
    sig do
      params(
        event_name: String,
        args: T.untyped,
        object: Object,
        scope: T.nilable(T.any(Symbol, String))
      ).void
    end
    def trigger(event_name, args, object, scope: nil); end

    # `event` was triggered on `object`, and `subscription_id` was subscribed,
    # so it should be updated.
    # 
    # Load `subscription_id`'s GraphQL data, re-evaluate the query, and deliver the result.
    # 
    # This is where a queue may be inserted to push updates in the background.
    # 
    # _@param_ `subscription_id` — 
    # 
    # _@param_ `event` — The event which was triggered
    # 
    # _@param_ `object` — The value for the subscription field
    sig { params(subscription_id: String, event: GraphQL::Subscriptions::Event, object: Object).void }
    def execute(subscription_id, event, object); end

    # Event `event` occurred on `object`,
    # Update all subscribers.
    # 
    # _@param_ `event` — 
    # 
    # _@param_ `object` — 
    sig { params(event: Subscriptions::Event, object: Object).void }
    def execute_all(event, object); end

    # Get each `subscription_id` subscribed to `event.topic` and yield them
    # 
    # _@param_ `event` — 
    sig { params(event: GraphQL::Subscriptions::Event).void }
    def each_subscription_id(event); end

    # The system wants to send an update to this subscription.
    # Read its data and return it.
    # 
    # _@param_ `subscription_id` — 
    # 
    # _@return_ — Containing required keys
    sig { params(subscription_id: String).returns(T::Hash[T.untyped, T.untyped]) }
    def read_subscription(subscription_id); end

    # A subscription query was re-evaluated, returning `result`.
    # The result should be send to `subscription_id`.
    # 
    # _@param_ `subscription_id` — 
    # 
    # _@param_ `result` — 
    sig { params(subscription_id: String, result: T::Hash[T.untyped, T.untyped]).void }
    def deliver(subscription_id, result); end

    # `query` was executed and found subscriptions to `events`.
    # Update the database to reflect this new state.
    # 
    # _@param_ `query` — 
    # 
    # _@param_ `events` — 
    sig { params(query: GraphQL::Query, events: T::Array[GraphQL::Subscriptions::Event]).void }
    def write_subscription(query, events); end

    # A subscription was terminated server-side.
    # Clean up the database.
    # 
    # _@param_ `subscription_id` — 
    # 
    # _@return_ — void.
    sig { params(subscription_id: String).returns(T.untyped) }
    def delete_subscription(subscription_id); end

    # _@return_ — A new unique identifier for a subscription
    sig { returns(String) }
    def build_id; end

    # Convert a user-provided event name or argument
    # to the equivalent in GraphQL.
    # 
    # By default, it converts the identifier to camelcase.
    # Override this in a subclass to change the transformation.
    # 
    # _@param_ `event_or_arg_name` — 
    sig { params(event_or_arg_name: T.any(String, Symbol)).returns(String) }
    def normalize_name(event_or_arg_name); end

    # Recursively normalize `args` as belonging to `arg_owner`:
    # - convert symbols to strings,
    # - if needed, camelize the string (using {#normalize_name})
    # 
    # _@param_ `arg_owner` — 
    # 
    # _@param_ `args` — some GraphQL input value to coerce as `arg_owner`
    # 
    # _@return_ — normalized arguments value
    sig { params(event_name: T.untyped, arg_owner: T.any(GraphQL::Field, GraphQL::BaseType), args: T.any(T::Hash[T.untyped, T.untyped], T::Array[T.untyped], T.untyped)).returns(T.untyped) }
    def normalize_arguments(event_name, arg_owner, args); end

    # Raised when either:
    # - the triggered `event_name` doesn't match a field in the schema; or
    # - one or more arguments don't match the field arguments
    class InvalidTriggerError < GraphQL::Error
    end

    # This thing can be:
    # - Subscribed to by `subscription { ... }`
    # - Triggered by `MySchema.subscriber.trigger(name, arguments, obj)`
    # 
    # An array of `Event`s are passed to `store.register(query, events)`.
    class Event
      # _@return_ — Corresponds to the Subscription root field name
      sig { returns(String) }
      def name; end

      sig { returns(GraphQL::Query::Arguments) }
      def arguments; end

      sig { returns(GraphQL::Query::Context) }
      def context; end

      # _@return_ — An opaque string which identifies this event, derived from `name` and `arguments`
      sig { returns(String) }
      def topic; end

      sig do
        params(
          name: T.untyped,
          arguments: T.untyped,
          field: T.untyped,
          context: T.untyped,
          scope: T.untyped
        ).returns(Event)
      end
      def initialize(name:, arguments:, field: nil, context: nil, scope: nil); end

      # _@return_ — an identifier for this unit of subscription
      sig do
        params(
          name: T.untyped,
          arguments: T.untyped,
          field: T.untyped,
          scope: T.untyped
        ).returns(String)
      end
      def self.serialize(name, arguments, field, scope:); end

      sig { params(args: T.untyped).returns(T.untyped) }
      def self.stringify_args(args); end
    end

    # Serialization helpers for passing subscription data around.
    # @api private
    module Serialize
      GLOBALID_KEY = T.let("__gid__", T.untyped)
      SYMBOL_KEY = T.let("__sym__", T.untyped)
      SYMBOL_KEYS_KEY = T.let("__sym_keys__", T.untyped)

      # _@param_ `str` — A serialized object from {.dump}
      # 
      # _@return_ — An object equivalent to the one passed to {.dump}
      sig { params(str: String).returns(Object) }
      def load(str); end

      # _@param_ `str` — A serialized object from {.dump}
      # 
      # _@return_ — An object equivalent to the one passed to {.dump}
      sig { params(str: String).returns(Object) }
      def self.load(str); end

      # _@param_ `obj` — Some subscription-related data to dump
      # 
      # _@return_ — The stringified object
      sig { params(obj: Object).returns(String) }
      def dump(obj); end

      # _@param_ `obj` — Some subscription-related data to dump
      # 
      # _@return_ — The stringified object
      sig { params(obj: Object).returns(String) }
      def self.dump(obj); end

      # This is for turning objects into subscription scopes.
      # It's a one-way transformation, can't reload this :'(
      # 
      # _@param_ `obj`
      sig { params(obj: Object).returns(String) }
      def dump_recursive(obj); end

      # This is for turning objects into subscription scopes.
      # It's a one-way transformation, can't reload this :'(
      # 
      # _@param_ `obj` — 
      sig { params(obj: Object).returns(String) }
      def self.dump_recursive(obj); end

      # _@param_ `value` — A parsed JSON object
      # 
      # _@return_ — An object that load Global::Identification recursive
      sig { params(value: Object).returns(Object) }
      def self.load_value(value); end

      # _@param_ `obj` — Some subscription-related data to dump
      # 
      # _@return_ — The object that converted Global::Identification
      sig { params(obj: Object).returns(Object) }
      def self.dump_value(obj); end
    end

    # Wrap the root fields of the subscription type with special logic for:
    # - Registering the subscription during the first execution
    # - Evaluating the triggered portion(s) of the subscription during later execution
    class Instrumentation
      sig { params(schema: T.untyped).returns(Instrumentation) }
      def initialize(schema:); end

      sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
      def instrument(type, field); end

      # If needed, prepare to gather events which this query subscribes to
      sig { params(query: T.untyped).returns(T.untyped) }
      def before_query(query); end

      # After checking the root fields, pass the gathered events to the store
      sig { params(query: T.untyped).returns(T.untyped) }
      def after_query(query); end

      class SubscriptionRegistrationResolve
        sig { params(inner_proc: T.untyped).returns(SubscriptionRegistrationResolve) }
        def initialize(inner_proc); end

        # Wrap the proc with subscription registration logic
        sig { params(obj: T.untyped, args: T.untyped, ctx: T.untyped).returns(T.untyped) }
        def call(obj, args, ctx); end
      end
    end

    # Extend this module in your subscription root when using {GraphQL::Execution::Interpreter}.
    module SubscriptionRoot
      sig { params(child_cls: T.untyped).returns(T.untyped) }
      def self.extended(child_cls); end

      sig do
        params(
          args: T.untyped,
          extensions: T.untyped,
          rest: T.untyped,
          block: T.untyped
        ).returns(T.untyped)
      end
      def field(*args, extensions: [], **rest, &block); end

      # This is for maintaining backwards compatibility:
      # if a subscription field is created without a `subscription:` resolver class,
      # then implement the method with the previous default behavior.
      module InstanceMethods
        sig { returns(T.untyped) }
        def skip_subscription_root; end
      end

      class Extension < GraphQL::Schema::FieldExtension
        sig do
          params(
            value: T.untyped,
            context: T.untyped,
            object: T.untyped,
            arguments: T.untyped,
            rest: T.untyped
          ).returns(T.untyped)
        end
        def after_resolve(value:, context:, object:, arguments:, **rest); end
      end
    end

    # A subscriptions implementation that sends data
    # as ActionCable broadcastings.
    # 
    # Experimental, some things to keep in mind:
    # 
    # - No queueing system; ActiveJob should be added
    # - Take care to reload context when re-delivering the subscription. (see {Query#subscription_update?})
    # 
    # @example Adding ActionCableSubscriptions to your schema
    #   MySchema = GraphQL::Schema.define do
    #     # ...
    #     use GraphQL::Subscriptions::ActionCableSubscriptions
    #   end
    # 
    # @example Implementing a channel for GraphQL Subscriptions
    #   class GraphqlChannel < ApplicationCable::Channel
    #     def subscribed
    #       @subscription_ids = []
    #     end
    # 
    #     def execute(data)
    #       query = data["query"]
    #       variables = ensure_hash(data["variables"])
    #       operation_name = data["operationName"]
    #       context = {
    #         # Re-implement whatever context methods you need
    #         # in this channel or ApplicationCable::Channel
    #         # current_user: current_user,
    #         # Make sure the channel is in the context
    #         channel: self,
    #       }
    # 
    #       result = MySchema.execute({
    #         query: query,
    #         context: context,
    #         variables: variables,
    #         operation_name: operation_name
    #       })
    # 
    #       payload = {
    #         result: result.to_h,
    #         more: result.subscription?,
    #       }
    # 
    #       # Track the subscription here so we can remove it
    #       # on unsubscribe.
    #       if result.context[:subscription_id]
    #         @subscription_ids << result.context[:subscription_id]
    #       end
    # 
    #       transmit(payload)
    #     end
    # 
    #     def unsubscribed
    #       @subscription_ids.each { |sid|
    #         MySchema.subscriptions.delete_subscription(sid)
    #       }
    #     end
    # 
    #     private
    # 
    #       def ensure_hash(ambiguous_param)
    #         case ambiguous_param
    #         when String
    #           if ambiguous_param.present?
    #             ensure_hash(JSON.parse(ambiguous_param))
    #           else
    #             {}
    #           end
    #         when Hash, ActionController::Parameters
    #           ambiguous_param
    #         when nil
    #           {}
    #         else
    #           raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    #         end
    #       end
    #   end
    class ActionCableSubscriptions < GraphQL::Subscriptions
      SUBSCRIPTION_PREFIX = T.let("graphql-subscription:", T.untyped)
      EVENT_PREFIX = T.let("graphql-event:", T.untyped)

      # _@param_ `serializer` — erializer [<#dump(obj), #load(string)] Used for serializing messages before handing them to `.broadcast(msg)`
      sig { params(serializer: T.untyped, rest: T.untyped).returns(ActionCableSubscriptions) }
      def initialize(serializer: Serialize, **rest); end

      # An event was triggered; Push the data over ActionCable.
      # Subscribers will re-evaluate locally.
      sig { params(event: T.untyped, object: T.untyped).returns(T.untyped) }
      def execute_all(event, object); end

      # This subscription was re-evaluated.
      # Send it to the specific stream where this client was waiting.
      sig { params(subscription_id: T.untyped, result: T.untyped).returns(T.untyped) }
      def deliver(subscription_id, result); end

      # A query was run where these events were subscribed to.
      # Store them in memory in _this_ ActionCable frontend.
      # It will receive notifications when events come in
      # and re-evaluate the query locally.
      sig { params(query: T.untyped, events: T.untyped).returns(T.untyped) }
      def write_subscription(query, events); end

      # Return the query from "storage" (in memory)
      sig { params(subscription_id: T.untyped).returns(T.untyped) }
      def read_subscription(subscription_id); end

      # The channel was closed, forget about it.
      sig { params(subscription_id: T.untyped).returns(T.untyped) }
      def delete_subscription(subscription_id); end
    end
  end

  class AnalysisError < GraphQL::ExecutionError
  end

  class CoercionError < GraphQL::Error
    # under the `extensions` key.
    # 
    # _@return_ — Optional custom data for error objects which will be added
    sig { returns(T::Hash[T.untyped, T.untyped]) }
    def extensions; end

    # under the `extensions` key.
    # 
    # _@return_ — Optional custom data for error objects which will be added
    sig { params(value: T::Hash[T.untyped, T.untyped]).returns(T::Hash[T.untyped, T.untyped]) }
    def extensions=(value); end

    sig { params(message: T.untyped, extensions: T.untyped).returns(CoercionError) }
    def initialize(message, extensions: nil); end
  end

  # There are two ways to apply the deprecated `!` DSL to class-style schema definitions:
  # 
  # 1. Scoped by file (CRuby only), add to the top of the file:
  # 
  #      using GraphQL::DeprecatedDSL
  # 
  #   (This is a "refinement", there are also other ways to scope it.)
  # 
  # 2. Global application, add before schema definition:
  # 
  #      GraphQL::DeprecatedDSL.activate
  module DeprecatedDSL
    TYPE_CLASSES = T.let([
  GraphQL::Schema::Scalar,
  GraphQL::Schema::Enum,
  GraphQL::Schema::InputObject,
  GraphQL::Schema::Union,
  GraphQL::Schema::Interface,
  GraphQL::Schema::Object,
], T.untyped)

    sig { returns(T.untyped) }
    def self.activate; end

    module Methods
      sig { returns(T.untyped) }
      def !; end
    end
  end

  module Execution
    # This wraps a value which is available, but not yet calculated, like a promise or future.
    # 
    # Calling `#value` will trigger calculation & return the "lazy" value.
    # 
    # This is an itty-bitty promise-like object, with key differences:
    # - It has only two states, not-resolved and resolved
    # - It has no error-catching functionality
    # @api private
    class Lazy
      NullResult = T.let(Lazy.new(){}, T.untyped)

      # Traverse `val`, lazily resolving any values along the way
      # 
      # _@param_ `val` — A data structure containing mixed plain values and `Lazy` instances
      # 
      # _@return_ — void
      sig { params(val: Object).returns(T.untyped) }
      def self.resolve(val); end

      sig { returns(T.untyped) }
      def path; end

      sig { returns(T.untyped) }
      def field; end

      # Create a {Lazy} which will get its inner value by calling the block
      # 
      # _@param_ `path` — 
      # 
      # _@param_ `field` — 
      # 
      # _@param_ `get_value_func` — a block to get the inner value (later)
      sig { params(path: T.nilable(T::Array[T.any(String, Integer)]), field: T.nilable(GraphQL::Schema::Field), get_value_func: T.untyped).returns(Lazy) }
      def initialize(path: nil, field: nil, &get_value_func); end

      # _@return_ — The wrapped value, calling the lazy block if necessary
      sig { returns(Object) }
      def value; end

      # _@return_ — A {Lazy} whose value depends on another {Lazy}, plus any transformations in `block`
      sig { returns(Lazy) }
      def then; end

      # _@param_ `lazies` — Maybe-lazy objects
      # 
      # _@return_ — A lazy which will sync all of `lazies`
      sig { params(lazies: T::Array[Object]).returns(Lazy) }
      def self.all(lazies); end

      # Helpers for dealing with data structures containing {Lazy} instances
      # @api private
      module Resolve
        sig { params(value: T.untyped).returns(T.untyped) }
        def self.resolve(value); end

        sig { params(value: T.untyped).returns(T.untyped) }
        def self.resolve_in_place(value); end

        # If `value` is a collection,
        # add any {Lazy} instances in the collection
        # to `acc`
        sig { params(acc: T.untyped, value: T.untyped).void }
        def self.each_lazy(acc, value); end

        # Traverse `val`, triggering resolution for each {Lazy}.
        # These {Lazy}s are expected to mutate their owner data structures
        # during resolution! (They're created with the `.then` calls in `resolve_in_place`).
        sig { params(val: T.untyped).void }
        def self.deep_sync(val); end

        # This object can be passed like an array, but it doesn't allocate an
        # array until it's used.
        # 
        # There's one crucial difference: you have to _capture_ the result
        # of `#<<`. (This _works_ with arrays but isn't required, since it has a side-effect.)
        # @api private
        module NullAccumulator
          sig { params(item: T.untyped).returns(T.untyped) }
          def self.<<(item); end

          sig { returns(T::Boolean) }
          def self.empty?; end
        end
      end

      # {GraphQL::Schema} uses this to match returned values to lazy resolution methods.
      # Methods may be registered for classes, they apply to its subclasses also.
      # The result of this lookup is cached for future resolutions.
      # Instances of this class are thread-safe.
      # @api private
      # @see {Schema#lazy?} looks up values from this map
      class LazyMethodMap
        sig { params(use_concurrent: T.untyped).returns(LazyMethodMap) }
        def initialize(use_concurrent: defined?(Concurrent::Map)); end

        sig { params(other: T.untyped).returns(T.untyped) }
        def initialize_copy(other); end

        # _@param_ `lazy_class` — A class which represents a lazy value (subclasses may also be used)
        # 
        # _@param_ `lazy_value_method` — The method to call on this class to get its value
        sig { params(lazy_class: Class, lazy_value_method: Symbol).returns(T.untyped) }
        def set(lazy_class, lazy_value_method); end

        # _@param_ `value` — an object which may have a `lazy_value_method` registered for its class or superclasses
        # 
        # _@return_ — The `lazy_value_method` for this object, or nil
        sig { params(value: Object).returns(T.nilable(Symbol)) }
        def get(value); end

        sig { returns(T.untyped) }
        def storage; end

        sig { params(value_class: T.untyped).returns(T.untyped) }
        def find_superclass_method(value_class); end

        # Mock the Concurrent::Map API
        class ConcurrentishMap
          extend Forwardable

          sig { returns(ConcurrentishMap) }
          def initialize; end

          sig { params(key: T.untyped, value: T.untyped).returns(T.untyped) }
          def []=(key, value); end

          sig { params(key: T.untyped).returns(T.untyped) }
          def compute_if_absent(key); end

          sig { params(other: T.untyped).returns(T.untyped) }
          def initialize_copy(other); end

          sig { returns(T.untyped) }
          def copy_storage; end
        end
      end
    end

    # A tracer that wraps query execution with error handling.
    # Supports class-based schemas and the new {Interpreter} runtime only.
    # 
    # @example Handling ActiveRecord::NotFound
    # 
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Execution::Errors
    # 
    #     rescue_from(ActiveRecord::NotFound) do |err, obj, args, ctx, field|
    #       ErrorTracker.log("Not Found: #{err.message}")
    #       nil
    #     end
    #   end
    class Errors
      sig { params(schema: T.untyped).returns(T.untyped) }
      def self.use(schema); end

      sig { params(schema: T.untyped).returns(Errors) }
      def initialize(schema); end

      sig { params(event: T.untyped, data: T.untyped).returns(T.untyped) }
      def trace(event, data); end

      sig { params(trace_data: T.untyped).returns(T.untyped) }
      def with_error_handling(trace_data); end
    end

    # A valid execution strategy
    # @api private
    class Execute
      include GraphQL::Execution::Execute::ExecutionFunctions
      SKIP = T.let(Skip.new, T.untyped)
      PROPAGATE_NULL = T.let(PropagateNull.new, T.untyped)

      sig { params(ast_operation: T.untyped, root_type: T.untyped, query: T.untyped).returns(T.untyped) }
      def execute(ast_operation, root_type, query); end

      sig { params(_multiplex: T.untyped).returns(T.untyped) }
      def self.begin_multiplex(_multiplex); end

      sig { params(query: T.untyped, _multiplex: T.untyped).returns(T.untyped) }
      def self.begin_query(query, _multiplex); end

      sig { params(results: T.untyped, multiplex: T.untyped).returns(T.untyped) }
      def self.finish_multiplex(results, multiplex); end

      sig { params(query: T.untyped, _multiplex: T.untyped).returns(T.untyped) }
      def self.finish_query(query, _multiplex); end

      sig { params(query: T.untyped).returns(T.untyped) }
      def resolve_root_selection(query); end

      sig { params(result: T.untyped, query: T.untyped, multiplex: T.untyped).returns(T.untyped) }
      def lazy_resolve_root_selection(result, query: nil, multiplex: nil); end

      sig do
        params(
          object: T.untyped,
          current_type: T.untyped,
          current_ctx: T.untyped,
          mutation: T.untyped
        ).returns(T.untyped)
      end
      def resolve_selection(object, current_type, current_ctx, mutation: false); end

      sig { params(object: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
      def resolve_field(object, field_ctx); end

      # If the returned object is lazy (unfinished),
      # assign the lazy object to `.value=` so we can resolve it later.
      # When we resolve it later, reassign it to `.value=` so that
      # the finished value replaces the unfinished one.
      # 
      # If the returned object is finished, continue to coerce
      # and resolve child fields
      sig { params(raw_value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
      def continue_or_wait(raw_value, field_type, field_ctx); end

      sig { params(raw_value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
      def continue_resolve_field(raw_value, field_type, field_ctx); end

      sig { params(value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
      def resolve_value(value, field_type, field_ctx); end

      # @api private
      class Skip
      end

      # @api private
      class PropagateNull
      end

      # @api private
      module ExecutionFunctions
        sig { params(query: T.untyped).returns(T.untyped) }
        def resolve_root_selection(query); end

        sig { params(query: T.untyped).returns(T.untyped) }
        def self.resolve_root_selection(query); end

        sig { params(result: T.untyped, query: T.untyped, multiplex: T.untyped).returns(T.untyped) }
        def lazy_resolve_root_selection(result, query: nil, multiplex: nil); end

        sig { params(result: T.untyped, query: T.untyped, multiplex: T.untyped).returns(T.untyped) }
        def self.lazy_resolve_root_selection(result, query: nil, multiplex: nil); end

        sig do
          params(
            object: T.untyped,
            current_type: T.untyped,
            current_ctx: T.untyped,
            mutation: T.untyped
          ).returns(T.untyped)
        end
        def resolve_selection(object, current_type, current_ctx, mutation: false); end

        sig do
          params(
            object: T.untyped,
            current_type: T.untyped,
            current_ctx: T.untyped,
            mutation: T.untyped
          ).returns(T.untyped)
        end
        def self.resolve_selection(object, current_type, current_ctx, mutation: false); end

        sig { params(object: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
        def resolve_field(object, field_ctx); end

        sig { params(object: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
        def self.resolve_field(object, field_ctx); end

        # If the returned object is lazy (unfinished),
        # assign the lazy object to `.value=` so we can resolve it later.
        # When we resolve it later, reassign it to `.value=` so that
        # the finished value replaces the unfinished one.
        # 
        # If the returned object is finished, continue to coerce
        # and resolve child fields
        sig { params(raw_value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
        def continue_or_wait(raw_value, field_type, field_ctx); end

        # If the returned object is lazy (unfinished),
        # assign the lazy object to `.value=` so we can resolve it later.
        # When we resolve it later, reassign it to `.value=` so that
        # the finished value replaces the unfinished one.
        # 
        # If the returned object is finished, continue to coerce
        # and resolve child fields
        sig { params(raw_value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
        def self.continue_or_wait(raw_value, field_type, field_ctx); end

        sig { params(raw_value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
        def continue_resolve_field(raw_value, field_type, field_ctx); end

        sig { params(raw_value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
        def self.continue_resolve_field(raw_value, field_type, field_ctx); end

        sig { params(value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
        def resolve_value(value, field_type, field_ctx); end

        sig { params(value: T.untyped, field_type: T.untyped, field_ctx: T.untyped).returns(T.untyped) }
        def self.resolve_value(value, field_type, field_ctx); end
      end

      # A `.call`-able suitable to be the last step in a middleware chain
      module FieldResolveStep
        # Execute the field's resolve method
        sig do
          params(
            _parent_type: T.untyped,
            parent_object: T.untyped,
            field_definition: T.untyped,
            field_args: T.untyped,
            context: T.untyped,
            _next: T.untyped
          ).returns(T.untyped)
        end
        def self.call(_parent_type, parent_object, field_definition, field_args, context, _next = nil); end
      end
    end

    # Starting from a root context,
    # create a hash out of the context tree.
    # @api private
    module Flatten
      sig { params(ctx: T.untyped).returns(T.untyped) }
      def self.call(ctx); end

      sig { params(obj: T.untyped).returns(T.untyped) }
      def self.flatten(obj); end
    end

    # @api private
    module Typecast
      sig { params(parent_type: T.untyped, child_type: T.untyped).returns(T::Boolean) }
      def self.subtype?(parent_type, child_type); end
    end

    # Lookahead creates a uniform interface to inspect the forthcoming selections.
    # 
    # It assumes that the AST it's working with is valid. (So, it's safe to use
    # during execution, but if you're using it directly, be sure to validate first.)
    # 
    # A field may get access to its lookahead by adding `extras: [:lookahead]`
    # to its configuration.
    # 
    # @example looking ahead in a field
    #   field :articles, [Types::Article], null: false,
    #     extras: [:lookahead]
    # 
    #   # For example, imagine a faster database call
    #   # may be issued when only some fields are requested.
    #   #
    #   # Imagine that _full_ fetch must be made to satisfy `fullContent`,
    #   # we can look ahead to see if we need that field. If we do,
    #   # we make the expensive database call instead of the cheap one.
    #   def articles(lookahead:)
    #     if lookahead.selects?(:full_content)
    #       fetch_full_articles(object)
    #     else
    #       fetch_preview_articles(object)
    #     end
    #   end
    class Lookahead
      NULL_LOOKAHEAD = T.let(NullLookahead.new, T.untyped)

      # _@param_ `query` — 
      # 
      # _@param_ `ast_nodes` — 
      # 
      # _@param_ `field` — if `ast_nodes` are fields, this is the field definition matching those nodes
      # 
      # _@param_ `root_type` — if `ast_nodes` are operation definition, this is the root type for that operation
      sig do
        params(
          query: GraphQL::Query,
          ast_nodes: T.any(T::Array[GraphQL::Language::Nodes::Field], T::Array[GraphQL::Language::Nodes::OperationDefinition]),
          field: T.nilable(GraphQL::Schema::Field),
          root_type: T.nilable(Class),
          owner_type: T.untyped
        ).returns(Lookahead)
      end
      def initialize(query:, ast_nodes:, field: nil, root_type: nil, owner_type: nil); end

      sig { returns(T::Array[GraphQL::Language::Nodes::Field]) }
      def ast_nodes; end

      sig { returns(GraphQL::Schema::Field) }
      def field; end

      sig { returns(T.any(GraphQL::Schema::Object, GraphQL::Schema::Union, GraphQL::Schema::Interface)) }
      def owner_type; end

      sig { returns(T::Hash[Symbol, Object]) }
      def arguments; end

      # True if this node has a selection on `field_name`.
      # If `field_name` is a String, it is treated as a GraphQL-style (camelized)
      # field name and used verbatim. If `field_name` is a Symbol, it is
      # treated as a Ruby-style (underscored) name and camelized before comparing.
      # 
      # If `arguments:` is provided, each provided key/value will be matched
      # against the arguments in the next selection. This method will return false
      # if any of the given `arguments:` are not present and matching in the next selection.
      # (But, the next selection may contain _more_ than the given arguments.)
      # 
      # _@param_ `field_name` — 
      # 
      # _@param_ `arguments` — Arguments which must match in the selection
      sig { params(field_name: T.any(String, Symbol), arguments: T.nilable(T::Hash[T.untyped, T.untyped])).returns(T::Boolean) }
      def selects?(field_name, arguments: nil); end

      # _@return_ — True if this lookahead represents a field that was requested
      sig { returns(T::Boolean) }
      def selected?; end

      # Like {#selects?}, but can be used for chaining.
      # It returns a null object (check with {#selected?})
      sig { params(field_name: T.untyped, selected_type: T.untyped, arguments: T.untyped).returns(GraphQL::Execution::Lookahead) }
      def selection(field_name, selected_type: @selected_type, arguments: nil); end

      # Like {#selection}, but for all nodes.
      # It returns a list of Lookaheads for all Selections
      # 
      # If `arguments:` is provided, each provided key/value will be matched
      # against the arguments in each selection. This method will filter the selections
      # if any of the given `arguments:` do not match the given selection.
      # 
      # _@param_ `arguments` — Arguments which must match in the selection
      # 
      # getting the name of a selection
      # ```ruby
      # def articles(lookahead:)
      #   next_lookaheads = lookahead.selections # => [#<GraphQL::Execution::Lookahead ...>, ...]
      #   next_lookaheads.map(&:name) #=> [:full_content, :title]
      # end
      # ```
      sig { params(arguments: T.nilable(T::Hash[T.untyped, T.untyped])).returns(T::Array[GraphQL::Execution::Lookahead]) }
      def selections(arguments: nil); end

      # The method name of the field.
      # It returns the method_sym of the Lookahead's field.
      # 
      # getting the name of a selection
      # ```ruby
      # def articles(lookahead:)
      #   article.selection(:full_content).name # => :full_content
      #   # ...
      # end
      # ```
      sig { returns(Symbol) }
      def name; end

      sig { returns(T.untyped) }
      def inspect; end

      # If it's a symbol, stringify and camelize it
      sig { params(name: T.untyped).returns(T.untyped) }
      def normalize_name(name); end

      sig { params(keyword: T.untyped).returns(T.untyped) }
      def normalize_keyword(keyword); end

      sig do
        params(
          subselections_by_type: T.untyped,
          selections_on_type: T.untyped,
          selected_type: T.untyped,
          ast_selections: T.untyped,
          arguments: T.untyped
        ).returns(T.untyped)
      end
      def find_selections(subselections_by_type, selections_on_type, selected_type, ast_selections, arguments); end

      # If a selection on `node` matches `field_name` (which is backed by `field_defn`)
      # and matches the `arguments:` constraints, then add that node to `matches`
      sig do
        params(
          node: T.untyped,
          field_name: T.untyped,
          field_defn: T.untyped,
          arguments: T.untyped,
          matches: T.untyped
        ).returns(T.untyped)
      end
      def find_selected_nodes(node, field_name, field_defn, arguments:, matches:); end

      sig { params(arguments: T.untyped, field_defn: T.untyped, field_node: T.untyped).returns(T::Boolean) }
      def arguments_match?(arguments, field_defn, field_node); end

      # This is returned for {Lookahead#selection} when a non-existent field is passed
      class NullLookahead < GraphQL::Execution::Lookahead
        NULL_LOOKAHEAD = T.let(NullLookahead.new, T.untyped)

        # No inputs required here.
        sig { returns(NullLookahead) }
        def initialize; end

        sig { returns(T::Boolean) }
        def selected?; end

        sig { returns(T::Boolean) }
        def selects?; end

        sig { returns(T.untyped) }
        def selection; end

        sig { returns(T.untyped) }
        def selections; end

        sig { returns(T.untyped) }
        def inspect; end
      end

      # TODO Dedup with interpreter
      module ArgumentHelpers
        sig do
          params(
            query: T.untyped,
            graphql_object: T.untyped,
            arg_owner: T.untyped,
            ast_node: T.untyped
          ).returns(T.untyped)
        end
        def arguments(query, graphql_object, arg_owner, ast_node); end

        sig do
          params(
            query: T.untyped,
            graphql_object: T.untyped,
            arg_owner: T.untyped,
            ast_node: T.untyped
          ).returns(T.untyped)
        end
        def self.arguments(query, graphql_object, arg_owner, ast_node); end

        # Get a Ruby-ready value from a client query.
        # 
        # _@param_ `graphql_object` — The owner of the field whose argument this is
        # 
        # _@param_ `arg_type`
        # 
        # _@param_ `ast_value`
        sig do
          params(
            query: T.untyped,
            graphql_object: Object,
            arg_type: T.any(Class, GraphQL::Schema::NonNull, GraphQL::Schema::List),
            ast_value: T.any(GraphQL::Language::Nodes::VariableIdentifier, String, Integer, Float, T::Boolean)
          ).returns([T.untyped, T.untyped])
        end
        def arg_to_value(query, graphql_object, arg_type, ast_value); end

        # Get a Ruby-ready value from a client query.
        # 
        # _@param_ `graphql_object` — The owner of the field whose argument this is
        # 
        # _@param_ `arg_type` — 
        # 
        # _@param_ `ast_value` — 
        sig do
          params(
            query: T.untyped,
            graphql_object: Object,
            arg_type: T.any(Class, GraphQL::Schema::NonNull, GraphQL::Schema::List),
            ast_value: T.any(GraphQL::Language::Nodes::VariableIdentifier, String, Integer, Float, T::Boolean)
          ).returns([T.untyped, T.untyped])
        end
        def self.arg_to_value(query, graphql_object, arg_type, ast_value); end

        sig { params(query: T.untyped, v: T.untyped).returns(T.untyped) }
        def flatten_ast_value(query, v); end

        sig { params(query: T.untyped, v: T.untyped).returns(T.untyped) }
        def self.flatten_ast_value(query, v); end
      end

      # TODO dedup with interpreter
      module FieldHelpers
        sig { params(schema: T.untyped, owner_type: T.untyped, field_name: T.untyped).returns(T.untyped) }
        def get_field(schema, owner_type, field_name); end

        sig { params(schema: T.untyped, owner_type: T.untyped, field_name: T.untyped).returns(T.untyped) }
        def self.get_field(schema, owner_type, field_name); end
      end
    end

    # Execute multiple queries under the same multiplex "umbrella".
    # They can share a batching context and reduce redundant database hits.
    # 
    # The flow is:
    # 
    # - Multiplex instrumentation setup
    # - Query instrumentation setup
    # - Analyze the multiplex + each query
    # - Begin each query
    # - Resolve lazy values, breadth-first across all queries
    # - Finish each query (eg, get errors)
    # - Query instrumentation teardown
    # - Multiplex instrumentation teardown
    # 
    # If one query raises an application error, all queries will be in undefined states.
    # 
    # Validation errors and {GraphQL::ExecutionError}s are handled in isolation:
    # one of these errors in one query will not affect the other queries.
    # 
    # @see {Schema#multiplex} for public API
    # @api private
    class Multiplex
      include GraphQL::Tracing::Traceable
      NO_OPERATION = T.let({}.freeze, T.untyped)
      DEFAULT_STRATEGIES = T.let([
  GraphQL::Execution::Execute,
  GraphQL::Execution::Interpreter
], T.untyped)

      sig { returns(T.untyped) }
      def context; end

      sig { returns(T.untyped) }
      def queries; end

      sig { returns(T.untyped) }
      def schema; end

      sig { returns(T.untyped) }
      def max_complexity; end

      sig do
        params(
          schema: T.untyped,
          queries: T.untyped,
          context: T.untyped,
          max_complexity: T.untyped
        ).returns(Multiplex)
      end
      def initialize(schema:, queries:, context:, max_complexity:); end

      sig { params(schema: T.untyped, query_options: T.untyped, args: T.untyped).returns(T.untyped) }
      def self.run_all(schema, query_options, *args); end

      # _@param_ `schema` — 
      # 
      # _@param_ `queries` — 
      # 
      # _@param_ `context` — 
      # 
      # _@param_ `max_complexity` — 
      # 
      # _@return_ — One result per query
      sig do
        params(
          schema: GraphQL::Schema,
          queries: T::Array[GraphQL::Query],
          context: T::Hash[T.untyped, T.untyped],
          max_complexity: T.nilable(Integer)
        ).returns(T::Array[T::Hash[T.untyped, T.untyped]])
      end
      def self.run_queries(schema, queries, context: {}, max_complexity: schema.max_complexity); end

      sig { params(multiplex: T.untyped).returns(T.untyped) }
      def self.run_as_multiplex(multiplex); end

      # _@param_ `query` — 
      # 
      # _@return_ — The initial result (may not be finished if there are lazy values)
      sig { params(query: GraphQL::Query, multiplex: T.untyped).returns(T::Hash[T.untyped, T.untyped]) }
      def self.begin_query(query, multiplex); end

      # _@param_ `data_result` — The result for the "data" key, if any
      # 
      # _@param_ `query` — The query which was run
      # 
      # _@return_ — final result of this query, including all values and errors
      sig { params(data_result: T::Hash[T.untyped, T.untyped], query: GraphQL::Query, multiplex: T.untyped).returns(T::Hash[T.untyped, T.untyped]) }
      def self.finish_query(data_result, query, multiplex); end

      # use the old `query_execution_strategy` etc to run this query
      sig { params(schema: T.untyped, query: T.untyped).returns(T.untyped) }
      def self.run_one_legacy(schema, query); end

      # _@return_ — True if the schema is only using one strategy, and it's one that supports multiplexing.
      sig { params(schema: T.untyped).returns(T::Boolean) }
      def self.supports_multiplexing?(schema); end

      # Apply multiplex & query instrumentation to `queries`.
      # 
      # It yields when the queries should be executed, then runs teardown.
      sig { params(multiplex: T.untyped).returns(T.untyped) }
      def self.instrument_and_analyze(multiplex); end

      # _@param_ `key` — The name of the event in GraphQL internals
      # 
      # _@param_ `metadata` — Event-related metadata (can be anything)
      # 
      # _@return_ — Must return the value of the block
      sig { params(key: String, metadata: T::Hash[T.untyped, T.untyped]).returns(Object) }
      def trace(key, metadata); end

      # If there's a tracer at `idx`, call it and then increment `idx`.
      # Otherwise, yield.
      # 
      # _@param_ `idx` — Which tracer to call
      # 
      # _@param_ `key` — The current event name
      # 
      # _@param_ `metadata` — The current event object
      # 
      # _@return_ — Whatever the block returns
      sig { params(idx: Integer, key: String, metadata: Object).returns(T.untyped) }
      def call_tracers(idx, key, metadata); end
    end

    class Interpreter
      sig { returns(Interpreter) }
      def initialize; end

      # Support `Executor` :S
      sig { params(_operation: T.untyped, _root_type: T.untyped, query: T.untyped).returns(T.untyped) }
      def execute(_operation, _root_type, query); end

      sig { params(schema_defn: T.untyped).returns(T.untyped) }
      def self.use(schema_defn); end

      sig { params(multiplex: T.untyped).returns(T.untyped) }
      def self.begin_multiplex(multiplex); end

      sig { params(query: T.untyped, multiplex: T.untyped).returns(T.untyped) }
      def self.begin_query(query, multiplex); end

      sig { params(_results: T.untyped, multiplex: T.untyped).returns(T.untyped) }
      def self.finish_multiplex(_results, multiplex); end

      sig { params(query: T.untyped, _multiplex: T.untyped).returns(T.untyped) }
      def self.finish_query(query, _multiplex); end

      # Run the eager part of `query`
      sig { params(query: T.untyped).returns(Interpreter::Runtime) }
      def evaluate(query); end

      # Run the lazy part of `query` or `multiplex`.
      sig { params(query: T.untyped, multiplex: T.untyped).void }
      def sync_lazies(query: nil, multiplex: nil); end

      module Resolve
        # Continue field results in `results` until there's nothing else to continue.
        sig { params(results: T.untyped).void }
        def self.resolve_all(results); end

        # After getting `results` back from an interpreter evaluation,
        # continue it until you get a response-ready Ruby value.
        # 
        # `results` is one level of _depth_ of a query or multiplex.
        # 
        # Resolve all lazy values in that depth before moving on
        # to the next level.
        # 
        # It's assumed that the lazies will
        # return {Lazy} instances if there's more work to be done,
        # or return {Hash}/{Array} if the query should be continued.
        # 
        # _@param_ `results` — 
        # 
        # _@return_ — Same size, filled with finished values
        sig { params(results: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
        def self.resolve(results); end
      end

      # I think it would be even better if we could somehow make
      # `continue_field` not recursive. "Trampolining" it somehow.
      # 
      # @api private
      class Runtime
        HALT = T.let(Object.new, T.untyped)

        sig { returns(GraphQL::Query) }
        def query; end

        sig { returns(Class) }
        def schema; end

        sig { returns(GraphQL::Query::Context) }
        def context; end

        sig { params(query: T.untyped, response: T.untyped).returns(Runtime) }
        def initialize(query:, response:); end

        sig { returns(T.untyped) }
        def final_value; end

        sig { returns(T.untyped) }
        def inspect; end

        # This _begins_ the execution. Some deferred work
        # might be stored up in lazies.
        sig { void }
        def run_eager; end

        sig do
          params(
            owner_object: T.untyped,
            owner_type: T.untyped,
            selections: T.untyped,
            selections_by_name: T.untyped
          ).returns(T.untyped)
        end
        def gather_selections(owner_object, owner_type, selections, selections_by_name); end

        sig do
          params(
            path: T.untyped,
            owner_object: T.untyped,
            owner_type: T.untyped,
            selections: T.untyped,
            root_operation_type: T.untyped
          ).returns(T.untyped)
        end
        def evaluate_selections(path, owner_object, owner_type, selections, root_operation_type: nil); end

        sig do
          params(
            path: T.untyped,
            value: T.untyped,
            field: T.untyped,
            is_non_null: T.untyped,
            ast_node: T.untyped
          ).returns(T.untyped)
        end
        def continue_value(path, value, field, is_non_null, ast_node); end

        # The resolver for `field` returned `value`. Continue to execute the query,
        # treating `value` as `type` (probably the return type of the field).
        # 
        # Use `next_selections` to resolve object fields, if there are any.
        # 
        # Location information from `path` and `ast_node`.
        # 
        # _@return_ — Lazy, Array, and Hash are all traversed to resolve lazy values later
        sig do
          params(
            arguments: T.untyped,
            value: T.untyped,
            field: T.untyped,
            type: T.untyped,
            ast_node: T.untyped,
            next_selections: T.untyped,
            is_non_null: T.untyped,
            owner_object: T.untyped,
            path: T.untyped
          ).returns(T.any(Lazy, T::Array[T.untyped], T::Hash[T.untyped, T.untyped], Object))
        end
        def continue_field(arguments, value, field, type, ast_node, next_selections, is_non_null, owner_object, path); end

        sig { params(object: T.untyped, ast_node: T.untyped).returns(T.untyped) }
        def resolve_with_directives(object, ast_node); end

        sig { params(object: T.untyped, ast_node: T.untyped, idx: T.untyped).returns(T.untyped) }
        def run_directive(object, ast_node, idx); end

        # Check {Schema::Directive.include?} for each directive that's present
        sig { params(node: T.untyped, graphql_object: T.untyped, parent_type: T.untyped).returns(T::Boolean) }
        def directives_include?(node, graphql_object, parent_type); end

        sig { params(type: T.untyped).returns(T.untyped) }
        def resolve_if_late_bound_type(type); end

        # _@param_ `obj` — Some user-returned value that may want to be batched
        # 
        # _@param_ `path` — 
        # 
        # _@param_ `field` — 
        # 
        # _@param_ `eager` — Set to `true` for mutation root fields only
        # 
        # _@return_ — If loading `object` will be deferred, it's a wrapper over it.
        sig do
          params(
            lazy_obj: T.untyped,
            owner: T.untyped,
            field: GraphQL::Schema::Field,
            path: T::Array[String],
            owner_object: T.untyped,
            arguments: T.untyped,
            eager: T::Boolean
          ).returns(T.any(GraphQL::Execution::Lazy, Object))
        end
        def after_lazy(lazy_obj, owner:, field:, path:, owner_object:, arguments:, eager: false); end

        sig { params(ast_args_or_hash: T.untyped).returns(T.untyped) }
        def each_argument_pair(ast_args_or_hash); end

        sig { params(graphql_object: T.untyped, arg_owner: T.untyped, ast_node_or_hash: T.untyped).returns(T.untyped) }
        def arguments(graphql_object, arg_owner, ast_node_or_hash); end

        # Get a Ruby-ready value from a client query.
        # 
        # _@param_ `graphql_object` — The owner of the field whose argument this is
        # 
        # _@param_ `arg_type` — 
        # 
        # _@param_ `ast_value` — 
        sig { params(graphql_object: Object, arg_type: T.any(Class, GraphQL::Schema::NonNull, GraphQL::Schema::List), ast_value: T.any(GraphQL::Language::Nodes::VariableIdentifier, String, Integer, Float, T::Boolean)).returns([T.untyped, T.untyped]) }
        def arg_to_value(graphql_object, arg_type, ast_value); end

        sig { params(v: T.untyped).returns(T.untyped) }
        def flatten_ast_value(v); end

        sig { params(path: T.untyped, invalid_null_error: T.untyped).returns(T.untyped) }
        def write_invalid_null_in_response(path, invalid_null_error); end

        sig { params(path: T.untyped, errors: T.untyped).returns(T.untyped) }
        def write_execution_errors_in_response(path, errors); end

        sig { params(path: T.untyped, value: T.untyped).returns(T.untyped) }
        def write_in_response(path, value); end

        # To propagate nulls, we have to know what the field type was
        # at previous parts of the response.
        # This hash matches the response
        sig { params(path: T.untyped).returns(T.untyped) }
        def type_at(path); end

        sig { params(path: T.untyped, type: T.untyped).returns(T.untyped) }
        def set_type_at_path(path, type); end

        # Mark `path` as having been permanently nulled out.
        # No values will be added beyond that path.
        sig { params(path: T.untyped).returns(T.untyped) }
        def add_dead_path(path); end

        sig { params(path: T.untyped).returns(T::Boolean) }
        def dead_path?(path); end
      end

      # This response class handles `#write` by accumulating
      # values into a Hash.
      class HashResponse
        sig { returns(HashResponse) }
        def initialize; end

        sig { returns(T.untyped) }
        def final_value; end

        sig { returns(T.untyped) }
        def inspect; end

        # Add `value` at `path`.
        sig { params(path: T.untyped, value: T.untyped).void }
        def write(path, value); end
      end

      class ExecutionErrors
        sig { params(ctx: T.untyped, ast_node: T.untyped, path: T.untyped).returns(ExecutionErrors) }
        def initialize(ctx, ast_node, path); end

        sig { params(err_or_msg: T.untyped).returns(T.untyped) }
        def add(err_or_msg); end
      end
    end

    module Instrumentation
      # This function implements the instrumentation policy:
      # 
      # - Instrumenters are a stack; the first `before_query` will have the last `after_query`
      # - If a `before_` hook returned without an error, its corresponding `after_` hook will run.
      # - If the `before_` hook did _not_ run, the `after_` hook will not be called.
      # 
      # When errors are raised from `after_` hooks:
      #   - Subsequent `after_` hooks _are_ called
      #   - The first raised error is captured; later errors are ignored
      #   - If an error was capture, it's re-raised after all hooks are finished
      # 
      # Partial runs of instrumentation are possible:
      # - If a `before_multiplex` hook raises an error, no `before_query` hooks will run
      # - If a `before_query` hook raises an error, subsequent `before_query` hooks will not run (on any query)
      sig { params(multiplex: T.untyped).returns(T.untyped) }
      def self.apply_instrumenters(multiplex); end

      # Call the before_ hooks of each query,
      # Then yield if no errors.
      # `call_hooks` takes care of appropriate cleanup.
      sig { params(instrumenters: T.untyped, queries: T.untyped, i: T.untyped).returns(T.untyped) }
      def self.each_query_call_hooks(instrumenters, queries, i = 0); end

      # Call each before hook, and if they all succeed, yield.
      # If they don't all succeed, call after_ for each one that succeeded.
      sig do
        params(
          instrumenters: T.untyped,
          object: T.untyped,
          before_hook_name: T.untyped,
          after_hook_name: T.untyped
        ).returns(T.untyped)
      end
      def self.call_hooks(instrumenters, object, before_hook_name, after_hook_name); end

      sig do
        params(
          instrumenters: T.untyped,
          object: T.untyped,
          after_hook_name: T.untyped,
          ex: T.untyped
        ).returns(T.untyped)
      end
      def self.call_after_hooks(instrumenters, object, after_hook_name, ex); end
    end

    # Boolean checks for how an AST node's directives should
    # influence its execution
    # @api private
    module DirectiveChecks
      SKIP = T.let("skip", T.untyped)
      INCLUDE = T.let("include", T.untyped)

      # _@return_ — Should this node be included in the query?
      sig { params(directive_ast_nodes: T.untyped, query: T.untyped).returns(T::Boolean) }
      def include?(directive_ast_nodes, query); end

      # _@return_ — Should this node be included in the query?
      sig { params(directive_ast_nodes: T.untyped, query: T.untyped).returns(T::Boolean) }
      def self.include?(directive_ast_nodes, query); end
    end
  end

  # An Interface contains a collection of types which implement some of the same fields.
  # 
  # Interfaces can have fields, defined with `field`, just like an object type.
  # 
  # Objects which implement this field _inherit_ field definitions from the interface.
  # An object type can override the inherited definition by redefining that field.
  # 
  # @example An interface with three fields
  #   DeviceInterface = GraphQL::InterfaceType.define do
  #     name("Device")
  #     description("Hardware devices for computing")
  # 
  #     field :ram, types.String
  #     field :processor, ProcessorType
  #     field :release_year, types.Int
  #   end
  # 
  # @example Implementing an interface with an object type
  #   Laptoptype = GraphQL::ObjectType.define do
  #     interfaces [DeviceInterface]
  #   end
  class InterfaceType < GraphQL::BaseType
    # Returns the value of attribute fields
    sig { returns(T.untyped) }
    def fields; end

    # Sets the attribute fields
    # 
    # _@param_ `value` — the value to set the attribute fields to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def fields=(value); end

    # Returns the value of attribute orphan_types
    sig { returns(T.untyped) }
    def orphan_types; end

    # Sets the attribute orphan_types
    # 
    # _@param_ `value` — the value to set the attribute orphan_types to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def orphan_types=(value); end

    # Returns the value of attribute resolve_type_proc
    sig { returns(T.untyped) }
    def resolve_type_proc; end

    # Sets the attribute resolve_type_proc
    # 
    # _@param_ `value` — the value to set the attribute resolve_type_proc to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def resolve_type_proc=(value); end

    sig { returns(InterfaceType) }
    def initialize; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    sig { returns(T.untyped) }
    def kind; end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def resolve_type(value, ctx); end

    sig { params(resolve_type_callable: T.untyped).returns(T.untyped) }
    def resolve_type=(resolve_type_callable); end

    # _@return_ — The defined field for `field_name`
    sig { params(field_name: T.untyped).returns(GraphQL::Field) }
    def get_field(field_name); end

    # These fields don't have instrumenation applied
    # 
    # _@return_ — All fields on this type
    # 
    # _@see_ `[Schema#get_fields]` — Get fields with instrumentation
    sig { returns(T::Array[GraphQL::Field]) }
    def all_fields; end

    # Get a possible type of this {InterfaceType} by type name
    # 
    # _@param_ `type_name` — 
    # 
    # _@param_ `ctx` — The context for the current query
    # 
    # _@return_ — The type named `type_name` if it exists and implements this {InterfaceType}, (else `nil`)
    sig { params(type_name: String, ctx: GraphQL::Query::Context).returns(T.nilable(GraphQL::ObjectType)) }
    def get_possible_type(type_name, ctx); end

    # Check if a type is a possible type of this {InterfaceType}
    # 
    # _@param_ `type` — Name of the type or a type definition
    # 
    # _@param_ `ctx` — The context for the current query
    # 
    # _@return_ — True if the `type` exists and is a member of this {InterfaceType}, (else `nil`)
    sig { params(type: T.any(String, GraphQL::BaseType), ctx: GraphQL::Query::Context).returns(T::Boolean) }
    def possible_type?(type, ctx); end
  end

  class NameValidator
    VALID_NAME_REGEX = T.let(/^[_a-zA-Z][_a-zA-Z0-9]*$/, T.untyped)

    sig { params(name: T.untyped).returns(T.untyped) }
    def self.validate!(name); end

    sig { params(name: T.untyped).returns(T::Boolean) }
    def self.valid?(name); end
  end

  # If a field's resolve function returns a {ExecutionError},
  # the error will be inserted into the response's `"errors"` key
  # and the field will resolve to `nil`.
  class ExecutionError < GraphQL::Error
    # _@return_ — the field where the error occurred
    sig { returns(GraphQL::Language::Nodes::Field) }
    def ast_node; end

    # _@return_ — the field where the error occurred
    sig { params(value: GraphQL::Language::Nodes::Field).returns(GraphQL::Language::Nodes::Field) }
    def ast_node=(value); end

    # response which corresponds to this error.
    # 
    # _@return_ — an array describing the JSON-path into the execution
    sig { returns(String) }
    def path; end

    # response which corresponds to this error.
    # 
    # _@return_ — an array describing the JSON-path into the execution
    sig { params(value: String).returns(String) }
    def path=(value); end

    # recommends that any custom entries in an error be under the
    # `extensions` key.
    # 
    # _@return_ — Optional data for error objects
    # 
    # _@deprecated_ — Use `extensions` instead of `options`. The GraphQL spec
    sig { returns(T::Hash[T.untyped, T.untyped]) }
    def options; end

    # recommends that any custom entries in an error be under the
    # `extensions` key.
    # 
    # _@return_ — Optional data for error objects
    # 
    # _@deprecated_ — Use `extensions` instead of `options`. The GraphQL spec
    sig { params(value: T::Hash[T.untyped, T.untyped]).returns(T::Hash[T.untyped, T.untyped]) }
    def options=(value); end

    # under the `extensions` key.
    # 
    # _@return_ — Optional custom data for error objects which will be added
    sig { returns(T::Hash[T.untyped, T.untyped]) }
    def extensions; end

    # under the `extensions` key.
    # 
    # _@return_ — Optional custom data for error objects which will be added
    sig { params(value: T::Hash[T.untyped, T.untyped]).returns(T::Hash[T.untyped, T.untyped]) }
    def extensions=(value); end

    sig do
      params(
        message: T.untyped,
        ast_node: T.untyped,
        options: T.untyped,
        extensions: T.untyped
      ).returns(ExecutionError)
    end
    def initialize(message, ast_node: nil, options: nil, extensions: nil); end

    # _@return_ — An entry for the response's "errors" key
    sig { returns(T::Hash[T.untyped, T.untyped]) }
    def to_h; end
  end

  module Upgrader
    GRAPHQL_TYPES = T.let('(Object|InputObject|Interface|Enum|Scalar|Union)', T.untyped)

    class Transform
      # _@param_ `input_text` — Untransformed GraphQL-Ruby code
      # 
      # _@return_ — The input text, with a transformation applied if necessary
      sig { params(input_text: String).returns(String) }
      def apply(input_text); end

      # Recursively transform a `.define`-DSL-based type expression into a class-ready expression, for example:
      # 
      # - `types[X]` -> `[X, null: true]`
      # - `types[X.to_non_null_type]` -> `[X]`
      # - `Int` -> `Integer`
      # - `X!` -> `X`
      # 
      # Notice that `!` is removed sometimes, because it doesn't exist in the class API.
      # 
      # _@param_ `type_expr` — A `.define`-ready expression of a return type or input type
      # 
      # _@return_ — A class-ready expression of the same type`
      sig { params(type_expr: String, preserve_bang: T.untyped).returns(String) }
      def normalize_type_expression(type_expr, preserve_bang: false); end

      sig { params(str: T.untyped).returns(T.untyped) }
      def underscorize(str); end

      sig { params(input_text: T.untyped, processor: T.untyped).returns(T.untyped) }
      def apply_processor(input_text, processor); end

      sig { params(input_text: T.untyped, from_indent: T.untyped, to_indent: T.untyped).returns(T.untyped) }
      def reindent_lines(input_text, from_indent:, to_indent:); end

      # Remove trailing whitespace
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def trim_lines(input_text); end
    end

    # Turns `{X} = GraphQL::{Y}Type.define do` into `class {X} < Types::Base{Y}`.
    class TypeDefineToClassTransform < GraphQL::Upgrader::Transform
      # _@param_ `base_class_pattern` — Replacement pattern for the base class name. Use this if your base classes have nonstandard names.
      sig { params(base_class_pattern: String).returns(TypeDefineToClassTransform) }
      def initialize(base_class_pattern: "Types::Base\\3"); end

      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Turns `{X} = GraphQL::Relay::Mutation.define do` into `class {X} < Mutations::BaseMutation`
    class MutationDefineToClassTransform < GraphQL::Upgrader::Transform
      # _@param_ `base_class_name` — Replacement pattern for the base class name. Use this if your Mutation base class has a nonstandard name.
      sig { params(base_class_name: String).returns(MutationDefineToClassTransform) }
      def initialize(base_class_name: "Mutations::BaseMutation"); end

      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Remove `name "Something"` if it is redundant with the class name.
    # Or, if it is not redundant, move it to `graphql_name "Something"`.
    class NameTransform < GraphQL::Upgrader::Transform
      sig { params(transformable: T.untyped).returns(T.untyped) }
      def apply(transformable); end
    end

    # Remove newlines -- normalize the text for processing
    class RemoveNewlinesTransform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Remove parens from method call - normalize for processing
    class RemoveMethodParensTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Move `type X` to be the second positional argument to `field ...`
    class PositionalTypeArgTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Find a configuration in the block and move it to a kwarg,
    # for example
    # ```
    # do
    #   property :thing
    # end
    # ```
    # becomes:
    # ```
    # property: thing
    # ```
    class ConfigurationToKwargTransform < GraphQL::Upgrader::Transform
      sig { params(kwarg: T.untyped).returns(ConfigurationToKwargTransform) }
      def initialize(kwarg:); end

      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Transform `property:` kwarg to `method:` kwarg
    class PropertyToMethodTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Find a keyword whose value is a string or symbol,
    # and if the value is equivalent to the field name,
    # remove the keyword altogether.
    class RemoveRedundantKwargTransform < GraphQL::Upgrader::Transform
      sig { params(kwarg: T.untyped).returns(RemoveRedundantKwargTransform) }
      def initialize(kwarg:); end

      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Take camelized field names and convert them to underscore case.
    # (They'll be automatically camelized later.)
    class UnderscoreizeFieldNameTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    class ProcToClassMethodTransform < GraphQL::Upgrader::Transform
      # _@param_ `proc_name` — The name of the proc to be moved to `def self.#{proc_name}`
      sig { params(proc_name: String).returns(ProcToClassMethodTransform) }
      def initialize(proc_name); end

      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end

      class NamedProcProcessor < Parser::AST::Processor
        # Returns the value of attribute proc_to_method_sections
        sig { returns(T.untyped) }
        def proc_to_method_sections; end

        sig { params(proc_name: T.untyped).returns(NamedProcProcessor) }
        def initialize(proc_name); end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_send(node); end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_block(node); end

        class ProcToMethodSection
          # Returns the value of attribute proc_arg_names
          sig { returns(T.untyped) }
          def proc_arg_names; end

          # Sets the attribute proc_arg_names
          # 
          # _@param_ `value` — the value to set the attribute proc_arg_names to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_arg_names=(value); end

          # Returns the value of attribute proc_defn_start
          sig { returns(T.untyped) }
          def proc_defn_start; end

          # Sets the attribute proc_defn_start
          # 
          # _@param_ `value` — the value to set the attribute proc_defn_start to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_defn_start=(value); end

          # Returns the value of attribute proc_defn_end
          sig { returns(T.untyped) }
          def proc_defn_end; end

          # Sets the attribute proc_defn_end
          # 
          # _@param_ `value` — the value to set the attribute proc_defn_end to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_defn_end=(value); end

          # Returns the value of attribute proc_defn_indent
          sig { returns(T.untyped) }
          def proc_defn_indent; end

          # Sets the attribute proc_defn_indent
          # 
          # _@param_ `value` — the value to set the attribute proc_defn_indent to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_defn_indent=(value); end

          # Returns the value of attribute proc_body_start
          sig { returns(T.untyped) }
          def proc_body_start; end

          # Sets the attribute proc_body_start
          # 
          # _@param_ `value` — the value to set the attribute proc_body_start to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_body_start=(value); end

          # Returns the value of attribute proc_body_end
          sig { returns(T.untyped) }
          def proc_body_end; end

          # Sets the attribute proc_body_end
          # 
          # _@param_ `value` — the value to set the attribute proc_body_end to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_body_end=(value); end

          # Returns the value of attribute inside_proc
          sig { returns(T.untyped) }
          def inside_proc; end

          # Sets the attribute inside_proc
          # 
          # _@param_ `value` — the value to set the attribute inside_proc to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def inside_proc=(value); end

          sig { returns(ProcToMethodSection) }
          def initialize; end
        end
      end
    end

    class MutationResolveProcToMethodTransform < GraphQL::Upgrader::Transform
      # _@param_ `proc_name` — The name of the proc to be moved to `def self.#{proc_name}`
      sig { params(proc_name: String).returns(MutationResolveProcToMethodTransform) }
      def initialize(proc_name: "resolve"); end

      # TODO dedup with ResolveProcToMethodTransform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Find hash literals which are returned from mutation resolves,
    # and convert their keys to underscores. This catches a lot of cases but misses
    # hashes which are initialized anywhere except in the return expression.
    class UnderscorizeMutationHashTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end

      class ReturnedHashLiteralProcessor < Parser::AST::Processor
        # Returns the value of attribute keys_to_upgrade
        sig { returns(T.untyped) }
        def keys_to_upgrade; end

        sig { returns(ReturnedHashLiteralProcessor) }
        def initialize; end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_def(node); end

        # Look for hash nodes, starting from `node`.
        # Return hash nodes that are valid candiates for returning from this method.
        sig { params(node: T.untyped, returning: T.untyped).returns(T.untyped) }
        def find_returned_hashes(node, returning:); end
      end
    end

    class ResolveProcToMethodTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end

      class ResolveProcProcessor < Parser::AST::Processor
        # Returns the value of attribute resolve_proc_sections
        sig { returns(T.untyped) }
        def resolve_proc_sections; end

        sig { returns(ResolveProcProcessor) }
        def initialize; end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_send(node); end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_block(node); end

        class ResolveProcSection
          # Returns the value of attribute proc_start
          sig { returns(T.untyped) }
          def proc_start; end

          # Sets the attribute proc_start
          # 
          # _@param_ `value` — the value to set the attribute proc_start to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_start=(value); end

          # Returns the value of attribute proc_end
          sig { returns(T.untyped) }
          def proc_end; end

          # Sets the attribute proc_end
          # 
          # _@param_ `value` — the value to set the attribute proc_end to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_end=(value); end

          # Returns the value of attribute proc_arg_names
          sig { returns(T.untyped) }
          def proc_arg_names; end

          # Sets the attribute proc_arg_names
          # 
          # _@param_ `value` — the value to set the attribute proc_arg_names to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def proc_arg_names=(value); end

          # Returns the value of attribute resolve_start
          sig { returns(T.untyped) }
          def resolve_start; end

          # Sets the attribute resolve_start
          # 
          # _@param_ `value` — the value to set the attribute resolve_start to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def resolve_start=(value); end

          # Returns the value of attribute resolve_end
          sig { returns(T.untyped) }
          def resolve_end; end

          # Sets the attribute resolve_end
          # 
          # _@param_ `value` — the value to set the attribute resolve_end to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def resolve_end=(value); end

          # Returns the value of attribute resolve_indent
          sig { returns(T.untyped) }
          def resolve_indent; end

          # Sets the attribute resolve_indent
          # 
          # _@param_ `value` — the value to set the attribute resolve_indent to.
          sig { params(value: T.untyped).returns(T.untyped) }
          def resolve_indent=(value); end

          sig { returns(ResolveProcSection) }
          def initialize; end
        end
      end
    end

    # Transform `interfaces [A, B, C]` to `implements A\nimplements B\nimplements C\n`
    class InterfacesToImplementsTransform < GraphQL::Upgrader::Transform
      PATTERN = T.let(/(?<indent>\s*)(?:interfaces) \[\s*(?<interfaces>(?:[a-zA-Z_0-9:\.,\s]+))\]/m, T.untyped)

      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Transform `possible_types [A, B, C]` to `possible_types(A, B, C)`
    class PossibleTypesTransform < GraphQL::Upgrader::Transform
      PATTERN = T.let(/(?<indent>\s*)(?:possible_types) \[\s*(?<possible_types>(?:[a-zA-Z_0-9:\.,\s]+))\]/m, T.untyped)

      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    class UpdateMethodSignatureTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    class RemoveEmptyBlocksTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Remove redundant newlines, which may have trailing spaces
    # Remove double newline after `do`
    # Remove double newline before `end`
    # Remove lines with whitespace only
    class RemoveExcessWhitespaceTransform < GraphQL::Upgrader::Transform
      sig { params(input_text: T.untyped).returns(T.untyped) }
      def apply(input_text); end
    end

    # Skip this file if you see any `field`
    # helpers with `null: true` or `null: false` keywords
    # or `argument` helpers with `required:` keywords,
    # because it's already been transformed
    class SkipOnNullKeyword
      sig { params(input_text: T.untyped).returns(T::Boolean) }
      def skip?(input_text); end
    end

    class Member
      DEFAULT_TYPE_TRANSFORMS = T.let([
  TypeDefineToClassTransform,
  MutationResolveProcToMethodTransform, # Do this before switching to class, so we can detect that its a mutation
  UnderscorizeMutationHashTransform,
  MutationDefineToClassTransform,
  NameTransform,
  InterfacesToImplementsTransform,
  PossibleTypesTransform,
  ProcToClassMethodTransform.new("coerce_input"),
  ProcToClassMethodTransform.new("coerce_result"),
  ProcToClassMethodTransform.new("resolve_type"),
], T.untyped)
      DEFAULT_FIELD_TRANSFORMS = T.let([
  RemoveNewlinesTransform,
  RemoveMethodParensTransform,
  PositionalTypeArgTransform,
  ConfigurationToKwargTransform.new(kwarg: "property"),
  ConfigurationToKwargTransform.new(kwarg: "description"),
  ConfigurationToKwargTransform.new(kwarg: "deprecation_reason"),
  ConfigurationToKwargTransform.new(kwarg: "hash_key"),
  PropertyToMethodTransform,
  UnderscoreizeFieldNameTransform,
  ResolveProcToMethodTransform,
  UpdateMethodSignatureTransform,
  RemoveRedundantKwargTransform.new(kwarg: "hash_key"),
  RemoveRedundantKwargTransform.new(kwarg: "method"),
], T.untyped)
      DEFAULT_CLEAN_UP_TRANSFORMS = T.let([
  RemoveExcessWhitespaceTransform,
  RemoveEmptyBlocksTransform,
], T.untyped)

      sig do
        params(
          member: T.untyped,
          skip: T.untyped,
          type_transforms: T.untyped,
          field_transforms: T.untyped,
          clean_up_transforms: T.untyped
        ).returns(Member)
      end
      def initialize(member, skip: SkipOnNullKeyword, type_transforms: DEFAULT_TYPE_TRANSFORMS, field_transforms: DEFAULT_FIELD_TRANSFORMS, clean_up_transforms: DEFAULT_CLEAN_UP_TRANSFORMS); end

      sig { returns(T.untyped) }
      def upgrade; end

      sig { returns(T::Boolean) }
      def upgradeable?; end

      sig { params(source_code: T.untyped, transforms: T.untyped, idx: T.untyped).returns(T.untyped) }
      def apply_transforms(source_code, transforms, idx: 0); end

      # Parse the type, find calls to `field` and `connection`
      # Return strings containing those calls
      sig { params(type_source: T.untyped).returns(T.untyped) }
      def find_fields(type_source); end

      class FieldFinder < Parser::AST::Processor
        DEFINITION_METHODS = T.let([:field, :connection, :input_field, :return_field, :argument], T.untyped)

        # Returns the value of attribute locations
        sig { returns(T.untyped) }
        def locations; end

        sig { returns(FieldFinder) }
        def initialize; end

        # _@param_ `send_node` — The node which might be a `field` call, etc
        # 
        # _@param_ `source_node` — The node whose source defines the bounds of the definition (eg, the surrounding block)
        sig { params(send_node: T.untyped, source_node: T.untyped).returns(T.untyped) }
        def add_location(send_node:, source_node:); end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_block(node); end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_send(node); end
      end
    end

    class Schema
      sig { params(schema: T.untyped).returns(Schema) }
      def initialize(schema); end

      sig { returns(T.untyped) }
      def upgrade; end

      # Returns the value of attribute schema
      sig { returns(T.untyped) }
      def schema; end
    end
  end

  # {InputObjectType}s are key-value inputs for fields.
  # 
  # Input objects have _arguments_ which are identical to {GraphQL::Field} arguments.
  # They map names to types and support default values.
  # Their input types can be any input types, including {InputObjectType}s.
  # 
  # @example An input type with name and number
  #   PlayerInput = GraphQL::InputObjectType.define do
  #     name("Player")
  #     argument :name, !types.String
  #     argument :number, !types.Int
  #   end
  # 
  # In a `resolve` function, you can access the values by making nested lookups on `args`.
  # 
  # @example Accessing input values in a resolve function
  #   resolve ->(obj, args, ctx) {
  #     args[:player][:name]    # => "Tony Gwynn"
  #     args[:player][:number]  # => 19
  #     args[:player].to_h      # { "name" => "Tony Gwynn", "number" => 19 }
  #     # ...
  #   }
  class InputObjectType < GraphQL::BaseType
    INVALID_OBJECT_MESSAGE = T.let("Expected %{object} to be a key, value object responding to `to_h` or `to_unsafe_h`.", T.untyped)

    # _@return_ — The mutation this field was derived from, if it was derived from a mutation
    sig { returns(T.nilable(GraphQL::Relay::Mutation)) }
    def mutation; end

    # _@return_ — The mutation this field was derived from, if it was derived from a mutation
    sig { params(value: T.nilable(GraphQL::Relay::Mutation)).returns(T.nilable(GraphQL::Relay::Mutation)) }
    def mutation=(value); end

    # _@return_ — Map String argument names to their {GraphQL::Argument} implementations
    sig { returns(T::Hash[String, GraphQL::Argument]) }
    def arguments; end

    # _@return_ — Map String argument names to their {GraphQL::Argument} implementations
    sig { params(value: T::Hash[String, GraphQL::Argument]).returns(T::Hash[String, GraphQL::Argument]) }
    def arguments=(value); end

    # Returns the value of attribute arguments_class
    sig { returns(T.untyped) }
    def arguments_class; end

    # Sets the attribute arguments_class
    # 
    # _@param_ `value` — the value to set the attribute arguments_class to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def arguments_class=(value); end

    sig { returns(InputObjectType) }
    def initialize; end

    sig { params(other: T.untyped).returns(T.untyped) }
    def initialize_copy(other); end

    sig { returns(T.untyped) }
    def kind; end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_result(value, ctx = nil); end

    sig { params(value: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def coerce_non_null_input(value, ctx); end

    sig { params(input: T.untyped, ctx: T.untyped).returns(T.untyped) }
    def validate_non_null_input(input, ctx); end
  end

  class InvalidNameError < GraphQL::ExecutionError
    # Returns the value of attribute name
    sig { returns(T.untyped) }
    def name; end

    # Returns the value of attribute valid_regex
    sig { returns(T.untyped) }
    def valid_regex; end

    sig { params(name: T.untyped, valid_regex: T.untyped).returns(InvalidNameError) }
    def initialize(name, valid_regex); end
  end

  # Raised automatically when a field's resolve function returns `nil`
  # for a non-null field.
  class InvalidNullError < GraphQL::RuntimeTypeError
    # _@return_ — The owner of {#field}
    sig { returns(GraphQL::BaseType) }
    def parent_type; end

    # _@return_ — The field which failed to return a value
    sig { returns(GraphQL::Field) }
    def field; end

    # _@return_ — The invalid value for this field
    sig { returns(T.nilable(GraphQL::ExecutionError)) }
    def value; end

    sig { params(parent_type: T.untyped, field: T.untyped, value: T.untyped).returns(InvalidNullError) }
    def initialize(parent_type, field, value); end

    # _@return_ — An entry for the response's "errors" key
    sig { returns(T::Hash[T.untyped, T.untyped]) }
    def to_h; end

    # 
    # _@deprecated_ — always false
    sig { returns(T::Boolean) }
    def parent_error?; end
  end

  class RuntimeTypeError < GraphQL::Error
  end

  # When an `authorized?` hook returns false, this error is used to communicate the failure.
  # It's passed to {Schema.unauthorized_object}.
  # 
  # Alternatively, custom code in `authorized?` may raise this error. It will be routed the same way.
  class UnauthorizedError < GraphQL::Error
    # _@return_ — the application object that failed the authorization check
    sig { returns(Object) }
    def object; end

    # _@return_ — the GraphQL object type whose `.authorized?` method was called (and returned false)
    sig { returns(Class) }
    def type; end

    # _@return_ — the context for the current query
    sig { returns(GraphQL::Query::Context) }
    def context; end

    sig do
      params(
        message: T.untyped,
        object: T.untyped,
        type: T.untyped,
        context: T.untyped
      ).returns(UnauthorizedError)
    end
    def initialize(message = nil, object: nil, type: nil, context: nil); end
  end

  module Pagination
    # A Connection wraps a list of items and provides cursor-based pagination over it.
    # 
    # Connections were introduced by Facebook's `Relay` front-end framework, but
    # proved to be generally useful for GraphQL APIs. When in doubt, use connections
    # to serve lists (like Arrays, ActiveRecord::Relations) via GraphQL.
    # 
    # Unlike the previous connection implementation, these default to bidirectional pagination.
    # 
    # Pagination arguments and context may be provided at initialization or assigned later (see {Schema::Field::ConnectionExtension}).
    class Connection
      # _@return_ — The class to use for wrapping items as `edges { ... }`. Defaults to `Connection::Edge`
      sig { returns(Class) }
      def self.edge_class; end

      # _@return_ — A list object, from the application. This is the unpaginated value passed into the connection.
      sig { returns(Object) }
      def items; end

      sig { returns(GraphQL::Query::Context) }
      def context; end

      sig { params(value: GraphQL::Query::Context).returns(GraphQL::Query::Context) }
      def context=(value); end

      # Returns the value of attribute before
      sig { returns(T.untyped) }
      def before; end

      # Sets the attribute before
      # 
      # _@param_ `value` — the value to set the attribute before to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def before=(value); end

      # Returns the value of attribute after
      sig { returns(T.untyped) }
      def after; end

      # Sets the attribute after
      # 
      # _@param_ `value` — the value to set the attribute after to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def after=(value); end

      # _@param_ `items` — some unpaginated collection item, like an `Array` or `ActiveRecord::Relation`
      # 
      # _@param_ `context` — 
      # 
      # _@param_ `first` — The limit parameter from the client, if it provided one
      # 
      # _@param_ `after` — A cursor for pagination, if the client provided one
      # 
      # _@param_ `last` — Limit parameter from the client, if provided
      # 
      # _@param_ `before` — A cursor for pagination, if the client provided one.
      sig do
        params(
          items: Object,
          context: T.nilable(Query::Context),
          first: T.nilable(Integer),
          after: T.nilable(String),
          max_page_size: T.untyped,
          last: T.nilable(Integer),
          before: T.nilable(String)
        ).returns(Connection)
      end
      def initialize(items, context: nil, first: nil, after: nil, max_page_size: nil, last: nil, before: nil); end

      # Sets the attribute max_page_size
      # 
      # _@param_ `value` — the value to set the attribute max_page_size to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def max_page_size=(value); end

      sig { returns(T.untyped) }
      def max_page_size; end

      # Sets the attribute first
      # 
      # _@param_ `value` — the value to set the attribute first to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def first=(value); end

      # _@return_ — a clamped `first` value. (The underlying instance variable doesn't have limits on it)
      sig { returns(T.nilable(Integer)) }
      def first; end

      # Sets the attribute last
      # 
      # _@param_ `value` — the value to set the attribute last to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def last=(value); end

      # _@return_ — a clamped `last` value. (The underlying instance variable doesn't have limits on it)
      sig { returns(T.nilable(Integer)) }
      def last; end

      # _@return_ — {nodes}, but wrapped with Edge instances
      sig { returns(T::Array[Edge]) }
      def edges; end

      # _@return_ — A slice of {items}, constrained by {@first}/{@after}/{@last}/{@before}
      sig { returns(T::Array[Object]) }
      def nodes; end

      # A dynamic alias for compatibility with {Relay::BaseConnection}.
      # 
      # _@deprecated_ — use {#nodes} instead
      sig { returns(T.untyped) }
      def edge_nodes; end

      # The connection object itself implements `PageInfo` fields
      sig { returns(T.untyped) }
      def page_info; end

      # _@return_ — True if there are more items after this page
      sig { returns(T::Boolean) }
      def has_next_page; end

      # _@return_ — True if there were items before these items
      sig { returns(T::Boolean) }
      def has_previous_page; end

      # _@return_ — The cursor of the first item in {nodes}
      sig { returns(String) }
      def start_cursor; end

      # _@return_ — The cursor of the last item in {nodes}
      sig { returns(String) }
      def end_cursor; end

      # Return a cursor for this item.
      # 
      # _@param_ `item` — one of the passed in {items}, taken from {nodes}
      sig { params(item: Object).returns(String) }
      def cursor_for(item); end

      # _@param_ `argument` — `first` or `last`, as provided by the client
      # 
      # _@param_ `max_page_size` — 
      # 
      # _@return_ — `nil` if the input was `nil`, otherwise a value between `0` and `max_page_size`
      sig { params(argument: T.nilable(Integer), max_page_size: T.nilable(Integer)).returns(T.nilable(Integer)) }
      def limit_pagination_argument(argument, max_page_size); end

      sig { params(cursor: T.untyped).returns(T.untyped) }
      def decode(cursor); end

      class PaginationImplementationMissingError < GraphQL::Error
      end

      # A wrapper around paginated items. It includes a {cursor} for pagination
      # and could be extended with custom relationship-level data.
      class Edge
        sig { params(item: T.untyped, connection: T.untyped).returns(Edge) }
        def initialize(item, connection); end

        sig { returns(T.untyped) }
        def node; end

        sig { returns(T.untyped) }
        def cursor; end
      end
    end

    # A schema-level connection wrapper manager.
    # 
    # Attach as a plugin.
    # 
    # @example Using new default connections
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Pagination::Connections
    #   end
    # 
    # @example Adding a custom wrapper
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Pagination::Connections
    #     connections.add(MyApp::SearchResults, MyApp::SearchResultsConnection)
    #   end
    # 
    # @example Removing default connection support for arrays (they can still be manually wrapped)
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Pagination::Connections
    #     connections.delete(Array)
    #   end
    # 
    # @see {Schema.connections}
    class Connections
      sig { params(schema_defn: T.untyped).returns(T.untyped) }
      def self.use(schema_defn); end

      sig { returns(Connections) }
      def initialize; end

      sig { params(nodes_class: T.untyped, implementation: T.untyped).returns(T.untyped) }
      def add(nodes_class, implementation); end

      sig { params(nodes_class: T.untyped).returns(T.untyped) }
      def delete(nodes_class); end

      # Used by the runtime to wrap values in connection wrappers.
      sig do
        params(
          field: T.untyped,
          object: T.untyped,
          arguments: T.untyped,
          context: T.untyped
        ).returns(T.untyped)
      end
      def wrap(field, object, arguments, context); end

      sig { returns(T.untyped) }
      def add_default; end

      class ImplementationMissingError < GraphQL::Error
      end
    end

    class ArrayConnection < GraphQL::Pagination::Connection
      sig { returns(T.untyped) }
      def nodes; end

      sig { returns(T.untyped) }
      def has_previous_page; end

      sig { returns(T.untyped) }
      def has_next_page; end

      sig { params(item: T.untyped).returns(T.untyped) }
      def cursor_for(item); end

      sig { params(cursor: T.untyped).returns(T.untyped) }
      def index_from_cursor(cursor); end

      # Populate all the pagination info _once_,
      # It doesn't do anything on subsequent calls.
      sig { returns(T.untyped) }
      def load_nodes; end
    end

    # A generic class for working with database query objects.
    class RelationConnection < GraphQL::Pagination::Connection
      sig { returns(T.untyped) }
      def nodes; end

      sig { returns(T.untyped) }
      def has_previous_page; end

      sig { returns(T.untyped) }
      def has_next_page; end

      sig { params(item: T.untyped).returns(T.untyped) }
      def cursor_for(item); end

      # _@param_ `relation` — A database query object
      # 
      # _@return_ — The offset value, or nil if there isn't one
      sig { params(relation: Object).returns(T.nilable(Integer)) }
      def relation_offset(relation); end

      # _@param_ `relation` — A database query object
      # 
      # _@return_ — The limit value, or nil if there isn't one
      sig { params(relation: Object).returns(T.nilable(Integer)) }
      def relation_limit(relation); end

      # _@param_ `relation` — A database query object
      # 
      # _@return_ — The number of items in this relation (hopefully determined without loading all records into memory!)
      sig { params(relation: Object).returns(T.nilable(Integer)) }
      def relation_count(relation); end

      # _@param_ `relation` — A database query object
      # 
      # _@return_ — A modified query object which will return no records
      sig { params(relation: Object).returns(Object) }
      def null_relation(relation); end

      sig { params(cursor: T.untyped).returns(T.untyped) }
      def offset_from_cursor(cursor); end

      # Abstract this operation so we can always ignore inputs less than zero.
      # (Sequel doesn't like it, understandably.)
      sig { params(relation: T.untyped, offset_value: T.untyped).returns(T.untyped) }
      def set_offset(relation, offset_value); end

      # Abstract this operation so we can always ignore inputs less than zero.
      # (Sequel doesn't like it, understandably.)
      sig { params(relation: T.untyped, limit_value: T.untyped).returns(T.untyped) }
      def set_limit(relation, limit_value); end

      # Populate all the pagination info _once_,
      # It doesn't do anything on subsequent calls.
      sig { returns(T.untyped) }
      def load_nodes; end
    end

    # Customizes `RelationConnection` to work with `Sequel::Dataset`s.
    class SequelDatasetConnection < GraphQL::Pagination::RelationConnection
      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_offset(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_limit(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_count(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def null_relation(relation); end
    end

    class MongoidRelationConnection < GraphQL::Pagination::RelationConnection
      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_offset(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_limit(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_count(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def null_relation(relation); end
    end

    # Customizes `RelationConnection` to work with `ActiveRecord::Relation`s.
    class ActiveRecordRelationConnection < GraphQL::Pagination::RelationConnection
      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_count(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_limit(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def relation_offset(relation); end

      sig { params(relation: T.untyped).returns(T.untyped) }
      def null_relation(relation); end
    end
  end

  class StringEncodingError < GraphQL::RuntimeTypeError
    # Returns the value of attribute string
    sig { returns(T.untyped) }
    def string; end

    sig { params(str: T.untyped).returns(StringEncodingError) }
    def initialize(str); end
  end

  # Error raised when the value provided for a field
  # can't be resolved to one of the possible types for the field.
  class UnresolvedTypeError < GraphQL::RuntimeTypeError
    # _@return_ — The runtime value which couldn't be successfully resolved with `resolve_type`
    sig { returns(Object) }
    def value; end

    # _@return_ — The field whose value couldn't be resolved (`field.type` is type which couldn't be resolved)
    sig { returns(GraphQL::Field) }
    def field; end

    # _@return_ — The owner of `field`
    sig { returns(GraphQL::BaseType) }
    def parent_type; end

    # _@return_ — The return of {Schema#resolve_type} for `value`
    sig { returns(Object) }
    def resolved_type; end

    # _@return_ — The allowed options for resolving `value` to `field.type`
    sig { returns(T::Array[GraphQL::BaseType]) }
    def possible_types; end

    sig do
      params(
        value: T.untyped,
        field: T.untyped,
        parent_type: T.untyped,
        resolved_type: T.untyped,
        possible_types: T.untyped
      ).returns(UnresolvedTypeError)
    end
    def initialize(value, field, parent_type, resolved_type, possible_types); end
  end

  # This error is raised when `Types::Int` is asked to return a value outside of 32-bit integer range.
  # 
  # For values outside that range, consider:
  # 
  # - `ID` for database primary keys or other identifiers
  # - `GraphQL::Types::BigInt` for really big integer values
  # 
  # @see GraphQL::Types::Int which raises this error
  class IntegerEncodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be encoded
    sig { returns(T.untyped) }
    def integer_value; end

    sig { params(value: T.untyped).returns(IntegerEncodingError) }
    def initialize(value); end
  end

  # Helpers for migrating in a backwards-compatible way
  # @api private
  module BackwardsCompatibility
    # Given a callable whose API used to take `from` arguments,
    # check its arity, and if needed, apply a wrapper so that
    # it can be called with `to` arguments.
    # If a wrapper is applied, warn the application with `name`.
    # 
    # If `last`, then use the last arguments to call the function.
    sig do
      params(
        callable: T.untyped,
        from: T.untyped,
        to: T.untyped,
        name: T.untyped,
        last: T.untyped
      ).returns(T.untyped)
    end
    def wrap_arity(callable, from:, to:, name:, last: false); end

    # Given a callable whose API used to take `from` arguments,
    # check its arity, and if needed, apply a wrapper so that
    # it can be called with `to` arguments.
    # If a wrapper is applied, warn the application with `name`.
    # 
    # If `last`, then use the last arguments to call the function.
    sig do
      params(
        callable: T.untyped,
        from: T.untyped,
        to: T.untyped,
        name: T.untyped,
        last: T.untyped
      ).returns(T.untyped)
    end
    def self.wrap_arity(callable, from:, to:, name:, last: false); end

    sig { params(callable: T.untyped).returns(T.untyped) }
    def get_arity(callable); end

    sig { params(callable: T.untyped).returns(T.untyped) }
    def self.get_arity(callable); end

    class FirstArgumentsWrapper
      sig { params(callable: T.untyped, old_arity: T.untyped).returns(FirstArgumentsWrapper) }
      def initialize(callable, old_arity); end

      sig { params(args: T.untyped).returns(T.untyped) }
      def call(*args); end
    end

    class LastArgumentsWrapper < GraphQL::BackwardsCompatibility::FirstArgumentsWrapper
      sig { params(args: T.untyped).returns(T.untyped) }
      def call(*args); end
    end
  end

  module StaticValidation
    ALL_RULES = T.let([
  GraphQL::StaticValidation::NoDefinitionsArePresent,
  GraphQL::StaticValidation::DirectivesAreDefined,
  GraphQL::StaticValidation::DirectivesAreInValidLocations,
  GraphQL::StaticValidation::UniqueDirectivesPerLocation,
  GraphQL::StaticValidation::OperationNamesAreValid,
  GraphQL::StaticValidation::FragmentNamesAreUnique,
  GraphQL::StaticValidation::FragmentsAreFinite,
  GraphQL::StaticValidation::FragmentsAreNamed,
  GraphQL::StaticValidation::FragmentsAreUsed,
  GraphQL::StaticValidation::FragmentTypesExist,
  GraphQL::StaticValidation::FragmentsAreOnCompositeTypes,
  GraphQL::StaticValidation::FragmentSpreadsArePossible,
  GraphQL::StaticValidation::FieldsAreDefinedOnType,
  GraphQL::StaticValidation::FieldsWillMerge,
  GraphQL::StaticValidation::FieldsHaveAppropriateSelections,
  GraphQL::StaticValidation::ArgumentsAreDefined,
  GraphQL::StaticValidation::ArgumentLiteralsAreCompatible,
  GraphQL::StaticValidation::RequiredArgumentsArePresent,
  GraphQL::StaticValidation::RequiredInputObjectAttributesArePresent,
  GraphQL::StaticValidation::ArgumentNamesAreUnique,
  GraphQL::StaticValidation::VariableNamesAreUnique,
  GraphQL::StaticValidation::VariablesAreInputTypes,
  GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTyped,
  GraphQL::StaticValidation::VariablesAreUsedAndDefined,
  GraphQL::StaticValidation::VariableUsagesAreAllowed,
  GraphQL::StaticValidation::MutationRootExists,
  GraphQL::StaticValidation::SubscriptionRootExists,
], T.untyped)

    # Generates GraphQL-compliant validation message.
    class Error
      # Returns the value of attribute message
      sig { returns(T.untyped) }
      def message; end

      # Returns the value of attribute path
      sig { returns(T.untyped) }
      def path; end

      # Sets the attribute path
      # 
      # _@param_ `value` — the value to set the attribute path to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def path=(value); end

      sig { params(message: T.untyped, path: T.untyped, nodes: T.untyped).returns(Error) }
      def initialize(message, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def locations; end

      # Convenience for validators
      module ErrorHelper
        # Error `error_message` is located at `node`
        sig do
          params(
            error_message: T.untyped,
            nodes: T.untyped,
            context: T.untyped,
            path: T.untyped,
            extensions: T.untyped
          ).returns(T.untyped)
        end
        def error(error_message, nodes, context: nil, path: nil, extensions: {}); end
      end
    end

    # Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Language::Nodes::Documents}s based on that schema.
    # 
    # By default, it's used by {GraphQL::Query}
    # 
    # @example Validate a query
    #   validator = GraphQL::StaticValidation::Validator.new(schema: MySchema)
    #   query = GraphQL::Query.new(MySchema, query_string)
    #   errors = validator.validate(query)[:errors]
    class Validator
      # _@param_ `schema` — 
      # 
      # _@param_ `rules` — a list of rules to use when validating
      sig { params(schema: GraphQL::Schema, rules: T::Array[T.untyped]).returns(Validator) }
      def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES); end

      # Validate `query` against the schema. Returns an array of message hashes.
      # 
      # _@param_ `query` — 
      sig { params(query: GraphQL::Query, validate: T.untyped).returns(T::Array[T::Hash[T.untyped, T.untyped]]) }
      def validate(query, validate: true); end
    end

    # - Ride along with `GraphQL::Language::Visitor`
    # - Track type info, expose it to validators
    class TypeStack
      TYPE_INFERRENCE_ROOTS = T.let([
  GraphQL::Language::Nodes::OperationDefinition,
  GraphQL::Language::Nodes::FragmentDefinition,
], T.untyped)
      PUSH_STRATEGIES = T.let({
  GraphQL::Language::Nodes::FragmentDefinition => FragmentDefinitionStrategy,
  GraphQL::Language::Nodes::InlineFragment => InlineFragmentStrategy,
  GraphQL::Language::Nodes::FragmentSpread => FragmentSpreadStrategy,
  GraphQL::Language::Nodes::Argument => ArgumentStrategy,
  GraphQL::Language::Nodes::Field => FieldStrategy,
  GraphQL::Language::Nodes::Directive => DirectiveStrategy,
  GraphQL::Language::Nodes::OperationDefinition => OperationDefinitionStrategy,
}, T.untyped)

      # _@return_ — the schema whose types are present in this document
      sig { returns(GraphQL::Schema) }
      def schema; end

      # When it enters an object (starting with query or mutation root), it's pushed on this stack.
      # When it exits, it's popped off.
      sig { returns(T::Array[T.any(GraphQL::ObjectType, T.untyped, T.untyped)]) }
      def object_types; end

      # When it enters a field, it's pushed on this stack (useful for nested fields, args).
      # When it exits, it's popped off.
      # 
      # _@return_ — fields which have been entered
      sig { returns(T::Array[GraphQL::Field]) }
      def field_definitions; end

      # Directives are pushed on, then popped off while traversing the tree
      # 
      # _@return_ — directives which have been entered
      sig { returns(T::Array[T.untyped]) }
      def directive_definitions; end

      # _@return_ — arguments which have been entered
      sig { returns(T::Array[T.untyped]) }
      def argument_definitions; end

      # _@return_ — fields which have been entered (by their AST name)
      sig { returns(T::Array[String]) }
      def path; end

      # _@param_ `schema` — the schema whose types to use when climbing this document
      # 
      # _@param_ `visitor` — a visitor to follow & watch the types
      sig { params(schema: GraphQL::Schema, visitor: GraphQL::Language::Visitor).returns(TypeStack) }
      def initialize(schema, visitor); end

      module FragmentWithTypeStrategy
        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def pop(stack, node); end
      end

      module FragmentDefinitionStrategy
        extend GraphQL::StaticValidation::TypeStack::FragmentWithTypeStrategy

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def push_path_member(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push_path_member(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.pop(stack, node); end
      end

      module InlineFragmentStrategy
        extend GraphQL::StaticValidation::TypeStack::FragmentWithTypeStrategy

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def push_path_member(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push_path_member(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.pop(stack, node); end
      end

      module OperationDefinitionStrategy
        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def pop(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.pop(stack, node); end
      end

      module FieldStrategy
        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def pop(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.pop(stack, node); end
      end

      module DirectiveStrategy
        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def pop(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.pop(stack, node); end
      end

      module ArgumentStrategy
        # Push `argument_defn` onto the stack.
        # It's possible that `argument_defn` will be nil.
        # Push it anyways so `pop` has something to pop.
        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def push(stack, node); end

        # Push `argument_defn` onto the stack.
        # It's possible that `argument_defn` will be nil.
        # Push it anyways so `pop` has something to pop.
        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def pop(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.pop(stack, node); end
      end

      module FragmentSpreadStrategy
        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.push(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def pop(stack, node); end

        sig { params(stack: T.untyped, node: T.untyped).returns(T.untyped) }
        def self.pop(stack, node); end
      end

      class EnterWithStrategy
        sig { params(stack: T.untyped, strategy: T.untyped).returns(EnterWithStrategy) }
        def initialize(stack, strategy); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def call(node, parent); end
      end

      class LeaveWithStrategy
        sig { params(stack: T.untyped, strategy: T.untyped).returns(LeaveWithStrategy) }
        def initialize(stack, strategy); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def call(node, parent); end
      end
    end

    class BaseVisitor < GraphQL::Language::Visitor
      SKIP = T.let(:_skip, T.untyped)
      DELETE_NODE = T.let(DeleteNode.new, T.untyped)

      sig { params(document: T.untyped, context: T.untyped).returns(BaseVisitor) }
      def initialize(document, context); end

      # This will be overwritten by {InternalRepresentation::Rewrite} if it's included
      sig { returns(T.untyped) }
      def rewrite_document; end

      # Returns the value of attribute context
      sig { returns(T.untyped) }
      def context; end

      # _@return_ — Types whose scope we've entered
      sig { returns(T::Array[GraphQL::ObjectType]) }
      def object_types; end

      # _@return_ — The nesting of the current position in the AST
      sig { returns(T::Array[String]) }
      def path; end

      # Build a class to visit the AST and perform validation,
      # or use a pre-built class if rules is `ALL_RULES` or empty.
      # 
      # _@param_ `rules` — 
      # 
      # _@param_ `rewrite` — if `false`, don't include rewrite
      # 
      # _@return_ — A class for validating `rules` during visitation
      sig { params(rules: T::Array[T.any(Module, Class)], rewrite: T::Boolean).returns(Class) }
      def self.including_rules(rules, rewrite: true); end

      sig { params(error: T.untyped, path: T.untyped).returns(T.untyped) }
      def add_error(error, path: nil); end

      module ContextMethods
        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_operation_definition(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_fragment_definition(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_inline_fragment(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_field(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_directive(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_argument(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_fragment_spread(node, parent); end

        sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
        def on_input_object(node, parent); end

        # _@return_ — The current object type
        sig { returns(GraphQL::BaseType) }
        def type_definition; end

        # _@return_ — The type which the current type came from
        sig { returns(GraphQL::BaseType) }
        def parent_type_definition; end

        # _@return_ — The most-recently-entered GraphQL::Field, if currently inside one
        sig { returns(T.nilable(GraphQL::Field)) }
        def field_definition; end

        # _@return_ — The most-recently-entered GraphQL::Directive, if currently inside one
        sig { returns(T.nilable(GraphQL::Directive)) }
        def directive_definition; end

        # _@return_ — The most-recently-entered GraphQL::Argument, if currently inside one
        sig { returns(T.nilable(GraphQL::Argument)) }
        def argument_definition; end

        sig { params(node: T.untyped).returns(T.untyped) }
        def on_fragment_with_type(node); end
      end
    end

    class DefaultVisitor < GraphQL::StaticValidation::BaseVisitor
      include GraphQL::StaticValidation::DefinitionDependencies
      include GraphQL::InternalRepresentation::Rewrite
      include ContextMethods
      NO_DIRECTIVES = T.let([].freeze, T.untyped)
      SKIP = T.let(:_skip, T.untyped)
      DELETE_NODE = T.let(DeleteNode.new, T.untyped)

      # _@return_ — InternalRepresentation::Document
      sig { returns(T.untyped) }
      def rewrite_document; end

      sig { returns(T.untyped) }
      def initialize; end

      # _@return_ — Roots of this query
      sig { returns(T::Hash[String, T.untyped]) }
      def operations; end

      sig { params(ast_node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(ast_node, parent); end

      sig { params(ast_node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(ast_node, parent); end

      sig { params(ast_node: T.untyped, definitions: T.untyped).returns(T.untyped) }
      def push_root_node(ast_node, definitions); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_inline_fragment(node, parent); end

      sig { params(ast_node: T.untyped, ast_parent: T.untyped).returns(T.untyped) }
      def on_field(ast_node, ast_parent); end

      sig { params(ast_node: T.untyped, ast_parent: T.untyped).returns(T.untyped) }
      def on_fragment_spread(ast_node, ast_parent); end

      sig { params(ast_node: T.untyped).returns(T::Boolean) }
      def skip?(ast_node); end

      # Returns the value of attribute dependencies
      sig { returns(T.untyped) }
      def dependencies; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end

      # A map of operation definitions to an array of that operation's dependencies
      sig { params(block: T.untyped).returns(DependencyMap) }
      def dependency_map(&block); end

      # Return a hash of { node => [node, node ... ]} pairs
      # Keys are top-level definitions
      # Values are arrays of flattened dependencies
      sig { returns(T.untyped) }
      def resolve_dependencies; end
    end

    # Test whether `ast_value` is a valid input for `type`
    class LiteralValidator
      sig { params(context: T.untyped).returns(LiteralValidator) }
      def initialize(context:); end

      sig { params(ast_value: T.untyped, type: T.untyped).returns(T.untyped) }
      def validate(ast_value, type); end

      sig { params(ast_value: T.untyped).returns(T.untyped) }
      def maybe_raise_if_invalid(ast_value); end

      # The GraphQL grammar supports variables embedded within scalars but graphql.js
      # doesn't support it so we won't either for simplicity
      sig { params(ast_value: T.untyped).returns(T::Boolean) }
      def constant_scalar?(ast_value); end

      sig { params(type: T.untyped, ast_node: T.untyped).returns(T.untyped) }
      def required_input_fields_are_present(type, ast_node); end

      sig { params(type: T.untyped, ast_node: T.untyped).returns(T.untyped) }
      def present_input_field_values_are_valid(type, ast_node); end

      sig { params(value: T.untyped).returns(T.untyped) }
      def ensure_array(value); end
    end

    # The validation context gets passed to each validator.
    # 
    # It exposes a {GraphQL::Language::Visitor} where validators may add hooks. ({Language::Visitor#visit} is called in {Validator#validate})
    # 
    # It provides access to the schema & fragments which validators may read from.
    # 
    # It holds a list of errors which each validator may add to.
    # 
    # It also provides limited access to the {TypeStack} instance,
    # which tracks state as you climb in and out of different fields.
    class ValidationContext
      extend Forwardable

      # Returns the value of attribute query
      sig { returns(T.untyped) }
      def query; end

      # Returns the value of attribute errors
      sig { returns(T.untyped) }
      def errors; end

      # Returns the value of attribute visitor
      sig { returns(T.untyped) }
      def visitor; end

      # Returns the value of attribute on_dependency_resolve_handlers
      sig { returns(T.untyped) }
      def on_dependency_resolve_handlers; end

      sig { params(query: T.untyped, visitor_class: T.untyped).returns(ValidationContext) }
      def initialize(query, visitor_class); end

      sig { params(handler: T.untyped).returns(T.untyped) }
      def on_dependency_resolve(&handler); end

      sig { params(ast_value: T.untyped, type: T.untyped).returns(T::Boolean) }
      def valid_literal?(ast_value, type); end
    end

    class InterpreterVisitor < GraphQL::StaticValidation::BaseVisitor
      include GraphQL::StaticValidation::DefinitionDependencies
      include ContextMethods
      SKIP = T.let(:_skip, T.untyped)
      DELETE_NODE = T.let(DeleteNode.new, T.untyped)

      # Returns the value of attribute dependencies
      sig { returns(T.untyped) }
      def dependencies; end

      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end

      sig { params(node: T.untyped, prev_node: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, prev_node); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_spread(node, parent); end

      # A map of operation definitions to an array of that operation's dependencies
      sig { params(block: T.untyped).returns(DependencyMap) }
      def dependency_map(&block); end

      # Return a hash of { node => [node, node ... ]} pairs
      # Keys are top-level definitions
      # Values are arrays of flattened dependencies
      sig { returns(T.untyped) }
      def resolve_dependencies; end
    end

    class NoValidateVisitor < GraphQL::StaticValidation::BaseVisitor
      include GraphQL::InternalRepresentation::Rewrite
      include GraphQL::StaticValidation::DefinitionDependencies
      include ContextMethods
      NO_DIRECTIVES = T.let([].freeze, T.untyped)
      SKIP = T.let(:_skip, T.untyped)
      DELETE_NODE = T.let(DeleteNode.new, T.untyped)

      # Returns the value of attribute dependencies
      sig { returns(T.untyped) }
      def dependencies; end

      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end

      sig { params(node: T.untyped, prev_node: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, prev_node); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_spread(node, parent); end

      # A map of operation definitions to an array of that operation's dependencies
      sig { params(block: T.untyped).returns(DependencyMap) }
      def dependency_map(&block); end

      # Return a hash of { node => [node, node ... ]} pairs
      # Keys are top-level definitions
      # Values are arrays of flattened dependencies
      sig { returns(T.untyped) }
      def resolve_dependencies; end

      # _@return_ — InternalRepresentation::Document
      sig { returns(T.untyped) }
      def rewrite_document; end

      # _@return_ — Roots of this query
      sig { returns(T::Hash[String, T.untyped]) }
      def operations; end

      sig { params(ast_node: T.untyped, definitions: T.untyped).returns(T.untyped) }
      def push_root_node(ast_node, definitions); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_inline_fragment(node, parent); end

      sig { params(ast_node: T.untyped, ast_parent: T.untyped).returns(T.untyped) }
      def on_field(ast_node, ast_parent); end

      sig { params(ast_node: T.untyped).returns(T::Boolean) }
      def skip?(ast_node); end
    end

    # Track fragment dependencies for operations
    # and expose the fragment definitions which
    # are used by a given operation
    module DefinitionDependencies
      # Returns the value of attribute dependencies
      sig { returns(T.untyped) }
      def dependencies; end

      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end

      sig { params(node: T.untyped, prev_node: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, prev_node); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_spread(node, parent); end

      # A map of operation definitions to an array of that operation's dependencies
      sig { params(block: T.untyped).returns(DependencyMap) }
      def dependency_map(&block); end

      # Return a hash of { node => [node, node ... ]} pairs
      # Keys are top-level definitions
      # Values are arrays of flattened dependencies
      sig { returns(T.untyped) }
      def resolve_dependencies; end

      # Map definition AST nodes to the definition AST nodes they depend on.
      # Expose circular dependencies.
      class DependencyMap
        sig { returns(T::Array[GraphQL::Language::Nodes::FragmentDefinition]) }
        def cyclical_definitions; end

        sig { returns(T::Hash[GraphQL::InternalRepresentation::Node, T::Array[GraphQL::Language::Nodes::FragmentSpread]]) }
        def unmet_dependencies; end

        sig { returns(T::Array[GraphQL::Language::Nodes::FragmentDefinition]) }
        def unused_dependencies; end

        sig { returns(DependencyMap) }
        def initialize; end

        # _@return_ — dependencies for `definition_node`
        sig { params(definition_node: T.untyped).returns(T::Array[GraphQL::Language::Nodes::AbstractNode]) }
        def [](definition_node); end
      end

      class NodeWithPath
        extend Forwardable

        # Returns the value of attribute node
        sig { returns(T.untyped) }
        def node; end

        # Returns the value of attribute path
        sig { returns(T.untyped) }
        def path; end

        sig { params(node: T.untyped, path: T.untyped).returns(NodeWithPath) }
        def initialize(node, path); end
      end
    end

    module FieldsWillMerge
      NO_ARGS = T.let({}.freeze, T.untyped)
      NO_SELECTIONS = T.let([{}.freeze, [].freeze].freeze, T.untyped)

      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, _parent); end

      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_field(node, _parent); end

      sig { params(node: T.untyped, parent_type: T.untyped).returns(T.untyped) }
      def conflicts_within_selection_set(node, parent_type); end

      sig { params(fragment_spread1: T.untyped, fragment_spread2: T.untyped, mutually_exclusive: T.untyped).returns(T.untyped) }
      def find_conflicts_between_fragments(fragment_spread1, fragment_spread2, mutually_exclusive:); end

      sig { params(fragment_spread: T.untyped, fields: T.untyped, mutually_exclusive: T.untyped).returns(T.untyped) }
      def find_conflicts_between_fields_and_fragment(fragment_spread, fields, mutually_exclusive:); end

      sig { params(response_keys: T.untyped).returns(T.untyped) }
      def find_conflicts_within(response_keys); end

      sig do
        params(
          response_key: T.untyped,
          field1: T.untyped,
          field2: T.untyped,
          mutually_exclusive: T.untyped
        ).returns(T.untyped)
      end
      def find_conflict(response_key, field1, field2, mutually_exclusive: false); end

      sig { params(field1: T.untyped, field2: T.untyped, mutually_exclusive: T.untyped).returns(T.untyped) }
      def find_conflicts_between_sub_selection_sets(field1, field2, mutually_exclusive:); end

      sig { params(response_keys: T.untyped, response_keys2: T.untyped, mutually_exclusive: T.untyped).returns(T.untyped) }
      def find_conflicts_between(response_keys, response_keys2, mutually_exclusive:); end

      sig { params(node: T.untyped, owner_type: T.untyped, parents: T.untyped).returns(T.untyped) }
      def fields_and_fragments_from_selection(node, owner_type:, parents:); end

      sig do
        params(
          selections: T.untyped,
          owner_type: T.untyped,
          parents: T.untyped,
          fields: T.untyped,
          fragment_spreads: T.untyped
        ).returns(T.untyped)
      end
      def find_fields_and_fragments(selections, owner_type:, parents:, fields:, fragment_spreads:); end

      sig { params(field1: T.untyped, field2: T.untyped).returns(T.untyped) }
      def possible_arguments(field1, field2); end

      sig { params(arg_value: T.untyped).returns(T.untyped) }
      def serialize_arg(arg_value); end

      sig { params(frag1: T.untyped, frag2: T.untyped, exclusive: T.untyped).returns(T.untyped) }
      def compared_fragments_key(frag1, frag2, exclusive); end

      # Given two list of parents, find out if they are mutually exclusive
      # In this context, `parents` represends the "self scope" of the field,
      # what types may be found at this point in the query.
      sig { params(parents1: T.untyped, parents2: T.untyped).returns(T::Boolean) }
      def mutually_exclusive?(parents1, parents2); end

      class Field < Struct
        # Sets the attribute node
        sig { params(value: Object).returns(Object) }
        def node=(value); end

        # Returns the value of attribute node
        sig { returns(Object) }
        def node; end

        # Sets the attribute definition
        sig { params(value: Object).returns(Object) }
        def definition=(value); end

        # Returns the value of attribute definition
        sig { returns(Object) }
        def definition; end

        # Sets the attribute owner_type
        sig { params(value: Object).returns(Object) }
        def owner_type=(value); end

        # Returns the value of attribute owner_type
        sig { returns(Object) }
        def owner_type; end

        # Sets the attribute parents
        sig { params(value: Object).returns(Object) }
        def parents=(value); end

        # Returns the value of attribute parents
        sig { returns(Object) }
        def parents; end
      end

      class FragmentSpread < Struct
        # Sets the attribute name
        sig { params(value: Object).returns(Object) }
        def name=(value); end

        # Returns the value of attribute name
        sig { returns(Object) }
        def name; end

        # Sets the attribute parents
        sig { params(value: Object).returns(Object) }
        def parents=(value); end

        # Returns the value of attribute parents
        sig { returns(Object) }
        def parents; end
      end
    end

    module FragmentsAreUsed
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end
    end

    module FragmentsAreNamed
      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(node, _parent); end
    end

    module FragmentTypesExist
      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(node, _parent); end

      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_inline_fragment(node, _parent); end

      sig { params(fragment_node: T.untyped).returns(T.untyped) }
      def validate_type_exists(fragment_node); end
    end

    module FragmentsAreFinite
      sig { params(_n: T.untyped, _p: T.untyped).returns(T.untyped) }
      def on_document(_n, _p); end
    end

    module MutationRootExists
      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, _parent); end
    end

    module ArgumentsAreDefined
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_argument(node, parent); end

      sig { params(parent: T.untyped, type_defn: T.untyped).returns(T.untyped) }
      def parent_name(parent, type_defn); end

      sig { params(parent: T.untyped).returns(T.untyped) }
      def node_type(parent); end
    end

    module DirectivesAreDefined
      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_directive(node, parent); end
    end

    class FieldsWillMergeError < GraphQL::StaticValidation::Error
      # Returns the value of attribute field_name
      sig { returns(T.untyped) }
      def field_name; end

      # Returns the value of attribute conflicts
      sig { returns(T.untyped) }
      def conflicts; end

      sig do
        params(
          message: T.untyped,
          field_name: T.untyped,
          conflicts: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(FieldsWillMergeError)
      end
      def initialize(message, field_name:, conflicts:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class FragmentsAreUsedError < GraphQL::StaticValidation::Error
      # Returns the value of attribute fragment_name
      sig { returns(T.untyped) }
      def fragment_name; end

      sig do
        params(
          message: T.untyped,
          fragment: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(FragmentsAreUsedError)
      end
      def initialize(message, fragment:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module SubscriptionRootExists
      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, _parent); end
    end

    module ArgumentNamesAreUnique
      include GraphQL::StaticValidation::Error::ErrorHelper

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_field(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_directive(node, parent); end

      sig { params(node: T.untyped).returns(T.untyped) }
      def validate_arguments(node); end

      # Error `error_message` is located at `node`
      sig do
        params(
          error_message: T.untyped,
          nodes: T.untyped,
          context: T.untyped,
          path: T.untyped,
          extensions: T.untyped
        ).returns(T.untyped)
      end
      def error(error_message, nodes, context: nil, path: nil, extensions: {}); end
    end

    module FragmentNamesAreUnique
      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(node, parent); end

      sig { params(_n: T.untyped, _p: T.untyped).returns(T.untyped) }
      def on_document(_n, _p); end
    end

    class FragmentsAreNamedError < GraphQL::StaticValidation::Error
      sig { params(message: T.untyped, path: T.untyped, nodes: T.untyped).returns(FragmentsAreNamedError) }
      def initialize(message, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module OperationNamesAreValid
      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end
    end

    module VariableNamesAreUnique
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, parent); end
    end

    module VariablesAreInputTypes
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_variable_definition(node, parent); end

      sig { params(ast_type: T.untyped).returns(T.untyped) }
      def get_type_name(ast_type); end
    end

    module FieldsAreDefinedOnType
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_field(node, parent); end
    end

    class FragmentTypesExistError < GraphQL::StaticValidation::Error
      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      sig do
        params(
          message: T.untyped,
          type: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(FragmentTypesExistError)
      end
      def initialize(message, type:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class FragmentsAreFiniteError < GraphQL::StaticValidation::Error
      # Returns the value of attribute fragment_name
      sig { returns(T.untyped) }
      def fragment_name; end

      sig do
        params(
          message: T.untyped,
          name: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(FragmentsAreFiniteError)
      end
      def initialize(message, name:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class MutationRootExistsError < GraphQL::StaticValidation::Error
      sig { params(message: T.untyped, path: T.untyped, nodes: T.untyped).returns(MutationRootExistsError) }
      def initialize(message, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module NoDefinitionsArePresent
      include GraphQL::StaticValidation::Error::ErrorHelper

      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_invalid_node(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end

      # Error `error_message` is located at `node`
      sig do
        params(
          error_message: T.untyped,
          nodes: T.untyped,
          context: T.untyped,
          path: T.untyped,
          extensions: T.untyped
        ).returns(T.untyped)
      end
      def error(error_message, nodes, context: nil, path: nil, extensions: {}); end
    end

    class ArgumentsAreDefinedError < GraphQL::StaticValidation::Error
      # Returns the value of attribute name
      sig { returns(T.untyped) }
      def name; end

      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute argument_name
      sig { returns(T.untyped) }
      def argument_name; end

      sig do
        params(
          message: T.untyped,
          name: T.untyped,
          type: T.untyped,
          argument: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(ArgumentsAreDefinedError)
      end
      def initialize(message, name:, type:, argument:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module VariableUsagesAreAllowed
      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_argument(node, parent); end

      sig { params(arguments: T.untyped, arg_node: T.untyped, ast_var: T.untyped).returns(T.untyped) }
      def validate_usage(arguments, arg_node, ast_var); end

      sig do
        params(
          error_message: T.untyped,
          var_type: T.untyped,
          ast_var: T.untyped,
          arg_defn: T.untyped,
          arg_node: T.untyped
        ).returns(T.untyped)
      end
      def create_error(error_message, var_type, ast_var, arg_defn, arg_node); end

      sig { params(var_type: T.untyped, arg_node: T.untyped).returns(T.untyped) }
      def wrap_var_type_with_depth_of_arg(var_type, arg_node); end

      # _@return_ — Returns the max depth of `array`, or `0` if it isn't an array at all
      sig { params(array: T.untyped).returns(Integer) }
      def depth_of_array(array); end

      sig { params(type: T.untyped).returns(T.untyped) }
      def list_dimension(type); end

      sig { params(arg_type: T.untyped, var_type: T.untyped).returns(T.untyped) }
      def non_null_levels_match(arg_type, var_type); end
    end

    class DirectivesAreDefinedError < GraphQL::StaticValidation::Error
      # Returns the value of attribute directive_name
      sig { returns(T.untyped) }
      def directive_name; end

      sig do
        params(
          message: T.untyped,
          directive: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(DirectivesAreDefinedError)
      end
      def initialize(message, directive:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module FragmentSpreadsArePossible
      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_inline_fragment(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_spread(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end

      sig do
        params(
          parent_type: T.untyped,
          child_type: T.untyped,
          node: T.untyped,
          context: T.untyped,
          path: T.untyped
        ).returns(T.untyped)
      end
      def validate_fragment_in_scope(parent_type, child_type, node, context, path); end

      class FragmentSpread
        # Returns the value of attribute node
        sig { returns(T.untyped) }
        def node; end

        # Returns the value of attribute parent_type
        sig { returns(T.untyped) }
        def parent_type; end

        # Returns the value of attribute path
        sig { returns(T.untyped) }
        def path; end

        sig { params(node: T.untyped, parent_type: T.untyped, path: T.untyped).returns(FragmentSpread) }
        def initialize(node:, parent_type:, path:); end
      end
    end

    module RequiredArgumentsArePresent
      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_field(node, _parent); end

      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_directive(node, _parent); end

      sig { params(ast_node: T.untyped, defn: T.untyped).returns(T.untyped) }
      def assert_required_args(ast_node, defn); end
    end

    class SubscriptionRootExistsError < GraphQL::StaticValidation::Error
      sig { params(message: T.untyped, path: T.untyped, nodes: T.untyped).returns(SubscriptionRootExistsError) }
      def initialize(message, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module UniqueDirectivesPerLocation
      DIRECTIVE_NODE_HOOKS = T.let([
  :on_fragment_definition,
  :on_fragment_spread,
  :on_inline_fragment,
  :on_operation_definition,
  :on_scalar_type_definition,
  :on_object_type_definition,
  :on_input_value_definition,
  :on_field_definition,
  :on_interface_type_definition,
  :on_union_type_definition,
  :on_enum_type_definition,
  :on_enum_value_definition,
  :on_input_object_type_definition,
  :on_field,
], T.untyped)

      sig { params(node: T.untyped).returns(T.untyped) }
      def validate_directive_location(node); end
    end

    # The problem is
    #   - Variable $usage must be determined at the OperationDefinition level
    #   - You can't tell how fragments use variables until you visit FragmentDefinitions (which may be at the end of the document)
    # 
    #  So, this validator includes some crazy logic to follow fragment spreads recursively, while avoiding infinite loops.
    # 
    # `graphql-js` solves this problem by:
    #   - re-visiting the AST for each validator
    #   - allowing validators to say `followSpreads: true`
    module VariablesAreUsedAndDefined
      sig { returns(T.untyped) }
      def initialize; end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(node, parent); end

      # For FragmentSpreads:
      #  - find the context on the stack
      #  - mark the context as containing this spread
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_spread(node, parent); end

      # For VariableIdentifiers:
      #  - mark the variable as used
      #  - assign its AST node
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_variable_identifier(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_document(node, parent); end

      # Follow spreads in `node`, looking them up from `spreads_for_context` and finding their match in `fragment_definitions`.
      # Use those fragments to update {VariableUsage}s in `parent_variables`.
      # Avoid infinite loops by skipping anything in `visited_fragments`.
      sig do
        params(
          node: T.untyped,
          parent_variables: T.untyped,
          spreads_for_context: T.untyped,
          fragment_definitions: T.untyped,
          visited_fragments: T.untyped
        ).returns(T.untyped)
      end
      def follow_spreads(node, parent_variables, spreads_for_context, fragment_definitions, visited_fragments); end

      # Determine all the error messages,
      # Then push messages into the validation context
      sig { params(node_variables: T.untyped).returns(T.untyped) }
      def create_errors(node_variables); end

      class VariableUsage
        # Returns the value of attribute ast_node
        sig { returns(T.untyped) }
        def ast_node; end

        # Sets the attribute ast_node
        # 
        # _@param_ `value` — the value to set the attribute ast_node to.
        sig { params(value: T.untyped).returns(T.untyped) }
        def ast_node=(value); end

        # Returns the value of attribute used_by
        sig { returns(T.untyped) }
        def used_by; end

        # Sets the attribute used_by
        # 
        # _@param_ `value` — the value to set the attribute used_by to.
        sig { params(value: T.untyped).returns(T.untyped) }
        def used_by=(value); end

        # Returns the value of attribute declared_by
        sig { returns(T.untyped) }
        def declared_by; end

        # Sets the attribute declared_by
        # 
        # _@param_ `value` — the value to set the attribute declared_by to.
        sig { params(value: T.untyped).returns(T.untyped) }
        def declared_by=(value); end

        # Returns the value of attribute path
        sig { returns(T.untyped) }
        def path; end

        # Sets the attribute path
        # 
        # _@param_ `value` — the value to set the attribute path to.
        sig { params(value: T.untyped).returns(T.untyped) }
        def path=(value); end

        sig { returns(T::Boolean) }
        def used?; end

        sig { returns(T::Boolean) }
        def declared?; end
      end
    end

    class ArgumentNamesAreUniqueError < GraphQL::StaticValidation::Error
      # Returns the value of attribute name
      sig { returns(T.untyped) }
      def name; end

      sig do
        params(
          message: T.untyped,
          name: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(ArgumentNamesAreUniqueError)
      end
      def initialize(message, name:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class FragmentNamesAreUniqueError < GraphQL::StaticValidation::Error
      # Returns the value of attribute fragment_name
      sig { returns(T.untyped) }
      def fragment_name; end

      sig do
        params(
          message: T.untyped,
          name: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(FragmentNamesAreUniqueError)
      end
      def initialize(message, name:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class OperationNamesAreValidError < GraphQL::StaticValidation::Error
      # Returns the value of attribute operation_name
      sig { returns(T.untyped) }
      def operation_name; end

      sig do
        params(
          message: T.untyped,
          path: T.untyped,
          nodes: T.untyped,
          name: T.untyped
        ).returns(OperationNamesAreValidError)
      end
      def initialize(message, path: nil, nodes: [], name: nil); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class VariableNamesAreUniqueError < GraphQL::StaticValidation::Error
      # Returns the value of attribute variable_name
      sig { returns(T.untyped) }
      def variable_name; end

      sig do
        params(
          message: T.untyped,
          name: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(VariableNamesAreUniqueError)
      end
      def initialize(message, name:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class VariablesAreInputTypesError < GraphQL::StaticValidation::Error
      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute variable_name
      sig { returns(T.untyped) }
      def variable_name; end

      sig do
        params(
          message: T.untyped,
          type: T.untyped,
          name: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(VariablesAreInputTypesError)
      end
      def initialize(message, type:, name:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module ArgumentLiteralsAreCompatible
      # TODO dedup with ArgumentsAreDefined
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_argument(node, parent); end

      sig { params(parent: T.untyped, type_defn: T.untyped).returns(T.untyped) }
      def parent_name(parent, type_defn); end

      sig { params(parent: T.untyped).returns(T.untyped) }
      def node_type(parent); end
    end

    class FieldsAreDefinedOnTypeError < GraphQL::StaticValidation::Error
      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute field_name
      sig { returns(T.untyped) }
      def field_name; end

      sig do
        params(
          message: T.untyped,
          type: T.untyped,
          field: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(FieldsAreDefinedOnTypeError)
      end
      def initialize(message, type:, field:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module FragmentsAreOnCompositeTypes
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(node, parent); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_inline_fragment(node, parent); end

      sig { params(node: T.untyped).returns(T.untyped) }
      def validate_type_is_composite(node); end
    end

    class NoDefinitionsArePresentError < GraphQL::StaticValidation::Error
      sig { params(message: T.untyped, path: T.untyped, nodes: T.untyped).returns(NoDefinitionsArePresentError) }
      def initialize(message, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module DirectivesAreInValidLocations
      include GraphQL::Language
      LOCATION_MESSAGE_NAMES = T.let({
  GraphQL::Directive::QUERY =>               "queries",
  GraphQL::Directive::MUTATION =>            "mutations",
  GraphQL::Directive::SUBSCRIPTION =>        "subscriptions",
  GraphQL::Directive::FIELD =>               "fields",
  GraphQL::Directive::FRAGMENT_DEFINITION => "fragment definitions",
  GraphQL::Directive::FRAGMENT_SPREAD =>     "fragment spreads",
  GraphQL::Directive::INLINE_FRAGMENT =>     "inline fragments",
}, T.untyped)
      SIMPLE_LOCATIONS = T.let({
  Nodes::Field =>               GraphQL::Directive::FIELD,
  Nodes::InlineFragment =>      GraphQL::Directive::INLINE_FRAGMENT,
  Nodes::FragmentSpread =>      GraphQL::Directive::FRAGMENT_SPREAD,
  Nodes::FragmentDefinition =>  GraphQL::Directive::FRAGMENT_DEFINITION,
}, T.untyped)
      SIMPLE_LOCATION_NODES = T.let(SIMPLE_LOCATIONS.keys, T.untyped)

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_directive(node, parent); end

      sig { params(ast_directive: T.untyped, ast_parent: T.untyped, directives: T.untyped).returns(T.untyped) }
      def validate_location(ast_directive, ast_parent, directives); end

      sig { params(directive_defn: T.untyped, directive_ast: T.untyped, required_location: T.untyped).returns(T.untyped) }
      def assert_includes_location(directive_defn, directive_ast, required_location); end
    end

    class VariableUsagesAreAllowedError < GraphQL::StaticValidation::Error
      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute variable_name
      sig { returns(T.untyped) }
      def variable_name; end

      # Returns the value of attribute argument_name
      sig { returns(T.untyped) }
      def argument_name; end

      # Returns the value of attribute error_message
      sig { returns(T.untyped) }
      def error_message; end

      sig do
        params(
          message: T.untyped,
          type: T.untyped,
          name: T.untyped,
          argument: T.untyped,
          error: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(VariableUsagesAreAllowedError)
      end
      def initialize(message, type:, name:, argument:, error:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    # Scalars _can't_ have selections
    # Objects _must_ have selections
    module FieldsHaveAppropriateSelections
      include GraphQL::StaticValidation::Error::ErrorHelper

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_field(node, parent); end

      sig { params(node: T.untyped, _parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(node, _parent); end

      sig { params(ast_node: T.untyped, resolved_type: T.untyped).returns(T.untyped) }
      def validate_field_selections(ast_node, resolved_type); end

      # Error `error_message` is located at `node`
      sig do
        params(
          error_message: T.untyped,
          nodes: T.untyped,
          context: T.untyped,
          path: T.untyped,
          extensions: T.untyped
        ).returns(T.untyped)
      end
      def error(error_message, nodes, context: nil, path: nil, extensions: {}); end
    end

    class FragmentSpreadsArePossibleError < GraphQL::StaticValidation::Error
      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute fragment_name
      sig { returns(T.untyped) }
      def fragment_name; end

      # Returns the value of attribute parent_name
      sig { returns(T.untyped) }
      def parent_name; end

      sig do
        params(
          message: T.untyped,
          type: T.untyped,
          fragment_name: T.untyped,
          parent: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(FragmentSpreadsArePossibleError)
      end
      def initialize(message, type:, fragment_name:, parent:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class RequiredArgumentsArePresentError < GraphQL::StaticValidation::Error
      # Returns the value of attribute class_name
      sig { returns(T.untyped) }
      def class_name; end

      # Returns the value of attribute name
      sig { returns(T.untyped) }
      def name; end

      # Returns the value of attribute arguments
      sig { returns(T.untyped) }
      def arguments; end

      sig do
        params(
          message: T.untyped,
          class_name: T.untyped,
          name: T.untyped,
          arguments: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(RequiredArgumentsArePresentError)
      end
      def initialize(message, class_name:, name:, arguments:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class UniqueDirectivesPerLocationError < GraphQL::StaticValidation::Error
      # Returns the value of attribute directive_name
      sig { returns(T.untyped) }
      def directive_name; end

      sig do
        params(
          message: T.untyped,
          directive: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(UniqueDirectivesPerLocationError)
      end
      def initialize(message, directive:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class VariablesAreUsedAndDefinedError < GraphQL::StaticValidation::Error
      VIOLATIONS = T.let({
  :VARIABLE_NOT_USED     => "variableNotUsed",
  :VARIABLE_NOT_DEFINED  => "variableNotDefined",
}, T.untyped)

      # Returns the value of attribute variable_name
      sig { returns(T.untyped) }
      def variable_name; end

      # Returns the value of attribute violation
      sig { returns(T.untyped) }
      def violation; end

      sig do
        params(
          message: T.untyped,
          name: T.untyped,
          error_type: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(VariablesAreUsedAndDefinedError)
      end
      def initialize(message, name:, error_type:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class ArgumentLiteralsAreCompatibleError < GraphQL::StaticValidation::Error
      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute argument_name
      sig { returns(T.untyped) }
      def argument_name; end

      sig do
        params(
          message: T.untyped,
          type: T.untyped,
          path: T.untyped,
          nodes: T.untyped,
          argument: T.untyped,
          extensions: T.untyped
        ).returns(ArgumentLiteralsAreCompatibleError)
      end
      def initialize(message, type:, path: nil, nodes: [], argument: nil, extensions: nil); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class FragmentsAreOnCompositeTypesError < GraphQL::StaticValidation::Error
      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute argument_name
      sig { returns(T.untyped) }
      def argument_name; end

      sig do
        params(
          message: T.untyped,
          type: T.untyped,
          path: T.untyped,
          nodes: T.untyped
        ).returns(FragmentsAreOnCompositeTypesError)
      end
      def initialize(message, type:, path: nil, nodes: []); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class DirectivesAreInValidLocationsError < GraphQL::StaticValidation::Error
      # Returns the value of attribute target_name
      sig { returns(T.untyped) }
      def target_name; end

      # Returns the value of attribute name
      sig { returns(T.untyped) }
      def name; end

      sig do
        params(
          message: T.untyped,
          target: T.untyped,
          path: T.untyped,
          nodes: T.untyped,
          name: T.untyped
        ).returns(DirectivesAreInValidLocationsError)
      end
      def initialize(message, target:, path: nil, nodes: [], name: nil); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class FieldsHaveAppropriateSelectionsError < GraphQL::StaticValidation::Error
      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute node_name
      sig { returns(T.untyped) }
      def node_name; end

      sig do
        params(
          message: T.untyped,
          node_name: T.untyped,
          path: T.untyped,
          nodes: T.untyped,
          type: T.untyped
        ).returns(FieldsHaveAppropriateSelectionsError)
      end
      def initialize(message, node_name:, path: nil, nodes: [], type: nil); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    module VariableDefaultValuesAreCorrectlyTyped
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_variable_definition(node, parent); end
    end

    module RequiredInputObjectAttributesArePresent
      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_input_object(node, parent); end

      sig { params(context: T.untyped, parent: T.untyped).returns(T.untyped) }
      def get_parent_type(context, parent); end

      sig { params(ast_node: T.untyped, context: T.untyped, parent: T.untyped).returns(T.untyped) }
      def validate_input_object(ast_node, context, parent); end
    end

    class VariableDefaultValuesAreCorrectlyTypedError < GraphQL::StaticValidation::Error
      VIOLATIONS = T.let({
  :INVALID_TYPE         => "defaultValueInvalidType",
  :INVALID_ON_NON_NULL  => "defaultValueInvalidOnNonNullVariable",
}, T.untyped)

      # Returns the value of attribute variable_name
      sig { returns(T.untyped) }
      def variable_name; end

      # Returns the value of attribute type_name
      sig { returns(T.untyped) }
      def type_name; end

      # Returns the value of attribute violation
      sig { returns(T.untyped) }
      def violation; end

      sig do
        params(
          message: T.untyped,
          name: T.untyped,
          error_type: T.untyped,
          path: T.untyped,
          nodes: T.untyped,
          type: T.untyped
        ).returns(VariableDefaultValuesAreCorrectlyTypedError)
      end
      def initialize(message, name:, error_type:, path: nil, nodes: [], type: nil); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end

    class RequiredInputObjectAttributesArePresentError < GraphQL::StaticValidation::Error
      # Returns the value of attribute argument_type
      sig { returns(T.untyped) }
      def argument_type; end

      # Returns the value of attribute argument_name
      sig { returns(T.untyped) }
      def argument_name; end

      # Returns the value of attribute input_object_type
      sig { returns(T.untyped) }
      def input_object_type; end

      sig do
        params(
          message: T.untyped,
          path: T.untyped,
          nodes: T.untyped,
          argument_type: T.untyped,
          argument_name: T.untyped,
          input_object_type: T.untyped
        ).returns(RequiredInputObjectAttributesArePresentError)
      end
      def initialize(message, path:, nodes:, argument_type:, argument_name:, input_object_type:); end

      # A hash representation of this Message
      sig { returns(T.untyped) }
      def to_h; end

      sig { returns(T.untyped) }
      def code; end
    end
  end

  class LiteralValidationError < GraphQL::Error
    # Returns the value of attribute ast_value
    sig { returns(T.untyped) }
    def ast_value; end

    # Sets the attribute ast_value
    # 
    # _@param_ `value` — the value to set the attribute ast_value to.
    sig { params(value: T.untyped).returns(T.untyped) }
    def ast_value=(value); end
  end

  class UnauthorizedFieldError < GraphQL::UnauthorizedError
    # _@return_ — the field that failed the authorization check
    sig { returns(Field) }
    def field; end

    # _@return_ — the field that failed the authorization check
    sig { params(value: Field).returns(Field) }
    def field=(value); end

    sig do
      params(
        message: T.untyped,
        object: T.untyped,
        type: T.untyped,
        context: T.untyped,
        field: T.untyped
      ).returns(UnauthorizedFieldError)
    end
    def initialize(message = nil, object: nil, type: nil, context: nil, field: nil); end
  end

  module InternalRepresentation
    class Node
      DEFAULT_TYPED_CHILDREN = T.let(Proc.new { |h, k| h[k] = {} }, T.untyped)
      NO_TYPED_CHILDREN = T.let(Hash.new({}.freeze), T.untyped)

      # _@return_ — the name this node has in the response
      sig { returns(String) }
      def name; end

      sig { returns(GraphQL::ObjectType) }
      def owner_type; end

      # Each key is a {GraphQL::ObjectType} which this selection _may_ be made on.
      # The values for that key are selections which apply to that type.
      # 
      # This value is derived from {#scoped_children} after the rewrite is finished.
      sig { returns(T::Hash[GraphQL::ObjectType, T::Hash[String, Node]]) }
      def typed_children; end

      # These children correspond closely to scopes in the AST.
      # Keys _may_ be abstract types. They're assumed to be read-only after rewrite is finished
      # because {#typed_children} is derived from them.
      # 
      # Using {#scoped_children} during the rewrite step reduces the overhead of reifying
      # abstract types because they're only reified _after_ the rewrite.
      sig { returns(T::Hash[GraphQL::BaseType, T::Hash[String, Node]]) }
      def scoped_children; end

      # _@return_ — AST nodes which are represented by this node
      sig { returns(T::Array[Language::Nodes::AbstractNode]) }
      def ast_nodes; end

      # _@return_ — Field definitions for this node (there should only be one!)
      sig { returns(T::Array[GraphQL::Field]) }
      def definitions; end

      # _@return_ — The expected wrapped type this node must return.
      sig { returns(GraphQL::BaseType) }
      def return_type; end

      sig { returns(T.nilable(InternalRepresentation::Node)) }
      def parent; end

      sig do
        params(
          name: T.untyped,
          owner_type: T.untyped,
          query: T.untyped,
          return_type: T.untyped,
          parent: T.untyped,
          ast_nodes: T.untyped,
          definitions: T.untyped
        ).returns(Node)
      end
      def initialize(name:, owner_type:, query:, return_type:, parent:, ast_nodes: [], definitions: []); end

      sig { params(other_node: T.untyped).returns(T.untyped) }
      def initialize_copy(other_node); end

      sig { params(other: T.untyped).returns(T.untyped) }
      def ==(other); end

      sig { returns(T.untyped) }
      def definition_name; end

      sig { returns(T.untyped) }
      def arguments; end

      sig { returns(T.untyped) }
      def definition; end

      sig { returns(T.untyped) }
      def ast_node; end

      sig { returns(T.untyped) }
      def inspect; end

      # Merge selections from `new_parent` into `self`.
      # Selections are merged in place, not copied.
      sig { params(new_parent: T.untyped, scope: T.untyped, merge_self: T.untyped).returns(T.untyped) }
      def deep_merge_node(new_parent, scope: nil, merge_self: true); end

      sig { returns(GraphQL::Query) }
      def query; end

      sig { returns(T.untyped) }
      def subscription_topic; end

      # Sets the attribute owner_type
      # 
      # _@param_ `value` — the value to set the attribute owner_type to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def owner_type=(value); end

      # Sets the attribute parent
      # 
      # _@param_ `value` — the value to set the attribute parent to.
      sig { params(value: T.untyped).returns(T.untyped) }
      def parent=(value); end

      # Get applicable children from {#scoped_children}
      # 
      # _@param_ `obj_type` — 
      sig { params(obj_type: GraphQL::ObjectType).returns(T::Hash[String, Node]) }
      def get_typed_children(obj_type); end
    end

    module Print
      sig { params(schema: T.untyped, query_string: T.untyped).returns(T.untyped) }
      def print(schema, query_string); end

      sig { params(schema: T.untyped, query_string: T.untyped).returns(T.untyped) }
      def self.print(schema, query_string); end

      sig { params(node: T.untyped, indent: T.untyped).returns(T.untyped) }
      def print_node(node, indent: 0); end

      sig { params(node: T.untyped, indent: T.untyped).returns(T.untyped) }
      def self.print_node(node, indent: 0); end
    end

    # At a point in the AST, selections may apply to one or more types.
    # {Scope} represents those types which selections may apply to.
    # 
    # Scopes can be defined by:
    # 
    # - A single concrete or abstract type
    # - An array of types
    # - `nil`
    # 
    # The AST may be scoped to an array of types when two abstractly-typed
    # fragments occur in inside one another.
    class Scope
      NO_TYPES = T.let([].freeze, T.untyped)

      # _@param_ `query` — 
      # 
      # _@param_ `type_defn` — 
      sig { params(query: GraphQL::Query, type_defn: T.nilable(T.any(GraphQL::BaseType, T::Array[GraphQL::BaseType]))).returns(Scope) }
      def initialize(query, type_defn); end

      # From a starting point of `self`, create a new scope by condition `other_type_defn`.
      # 
      # _@param_ `other_type_defn` — 
      sig { params(other_type_defn: T.nilable(GraphQL::BaseType)).returns(Scope) }
      def enter(other_type_defn); end

      # Call the block for each type in `self`.
      # This uses the simplest possible expression of `self`,
      # so if this scope is defined by an abstract type, it gets yielded.
      sig { returns(T.untyped) }
      def each; end

      sig { returns(T.untyped) }
      def concrete_types; end
    end

    # Traverse a re-written query tree, calling handlers for each node
    module Visit
      sig { params(operations: T.untyped, handlers: T.untyped).returns(T.untyped) }
      def visit_each_node(operations, handlers); end

      sig { params(operations: T.untyped, handlers: T.untyped).returns(T.untyped) }
      def self.visit_each_node(operations, handlers); end

      # Traverse a node in a rewritten query tree,
      # visiting the node itself and each of its typed children.
      sig { params(node: T.untyped).returns(T.untyped) }
      def each_node(node); end

      # Traverse a node in a rewritten query tree,
      # visiting the node itself and each of its typed children.
      sig { params(node: T.untyped).returns(T.untyped) }
      def self.each_node(node); end
    end

    # While visiting an AST, build a normalized, flattened tree of {InternalRepresentation::Node}s.
    # 
    # No unions or interfaces are present in this tree, only object types.
    # 
    # Selections from the AST are attached to the object types they apply to.
    # 
    # Inline fragments and fragment spreads are preserved in {InternalRepresentation::Node#ast_spreads},
    # where they can be used to check for the presence of directives. This might not be sufficient
    # for future directives, since the selections' grouping is lost.
    # 
    # The rewritten query tree serves as the basis for the `FieldsWillMerge` validation.
    module Rewrite
      include GraphQL::Language
      NO_DIRECTIVES = T.let([].freeze, T.untyped)

      # _@return_ — InternalRepresentation::Document
      sig { returns(T.untyped) }
      def rewrite_document; end

      sig { returns(T.untyped) }
      def initialize; end

      # _@return_ — Roots of this query
      sig { returns(T::Hash[String, Node]) }
      def operations; end

      sig { params(ast_node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_operation_definition(ast_node, parent); end

      sig { params(ast_node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_fragment_definition(ast_node, parent); end

      sig { params(ast_node: T.untyped, definitions: T.untyped).returns(T.untyped) }
      def push_root_node(ast_node, definitions); end

      sig { params(node: T.untyped, parent: T.untyped).returns(T.untyped) }
      def on_inline_fragment(node, parent); end

      sig { params(ast_node: T.untyped, ast_parent: T.untyped).returns(T.untyped) }
      def on_field(ast_node, ast_parent); end

      sig { params(ast_node: T.untyped, ast_parent: T.untyped).returns(T.untyped) }
      def on_fragment_spread(ast_node, ast_parent); end

      sig { params(ast_node: T.untyped).returns(T::Boolean) }
      def skip?(ast_node); end
    end

    class Document
      # _@return_ — Operation Nodes of this query
      sig { returns(T::Hash[String, Node]) }
      def operation_definitions; end

      # _@return_ — Fragment definition Nodes of this query
      sig { returns(T::Hash[String, Node]) }
      def fragment_definitions; end

      sig { returns(Document) }
      def initialize; end

      sig { params(key: T.untyped).returns(T.untyped) }
      def [](key); end

      sig { params(block: T.untyped).returns(T.untyped) }
      def each(&block); end
    end
  end

  # Raised when a argument is configured with `loads:` and the client provides an `ID`,
  # but no object is loaded for that ID.
  # 
  # @see GraphQL::Schema::Member::HasArguments::ArgumentObjectLoader#load_application_object_failed, A hook which you can override in resolvers, mutations and input objects.
  class LoadApplicationObjectFailedError < GraphQL::ExecutionError
    # _@return_ — the argument definition for the argument that was looked up
    sig { returns(GraphQL::Schema::Argument) }
    def argument; end

    # _@return_ — The ID provided by the client
    sig { returns(String) }
    def id; end

    # _@return_ — The value found with this ID
    sig { returns(Object) }
    def object; end

    sig { params(argument: T.untyped, id: T.untyped, object: T.untyped).returns(LoadApplicationObjectFailedError) }
    def initialize(argument:, id:, object:); end
  end

  module Compatibility
    # Test an execution strategy. This spec is not meant as a development aid.
    # Rather, when the strategy _works_, run it here to see if it has any differences
    # from the built-in strategy.
    # 
    # - Custom scalar input / output
    # - Null propagation
    # - Query-level masking
    # - Directive support
    # - Typecasting
    # - Error handling (raise / return GraphQL::ExecutionError)
    # - Provides Irep & AST node to resolve fn
    # - Skipping fields
    # 
    # Some things are explicitly _not_ tested here, because they're handled
    # by other parts of the system:
    # 
    # - Schema definition (including types and fields)
    # - Parsing & parse errors
    # - AST -> IRep transformation (eg, fragment merging)
    # - Query validation and analysis
    # - Relay features
    module ExecutionSpecification
      # Make a minitest suite for this execution strategy, making sure it
      # fulfills all the requirements of this library.
      # 
      # _@param_ `execution_strategy` — An execution strategy class
      # 
      # _@return_ — A test suite for this execution strategy
      sig { params(execution_strategy: T::Array[T.any(T.untyped, T.untyped)]).returns(T.untyped) }
      def self.build_suite(execution_strategy); end

      module CounterSchema
        sig { params(execution_strategy: T.untyped).returns(T.untyped) }
        def self.build(execution_strategy); end
      end

      module SpecificationSchema
        sig { params(execution_strategy: T.untyped).returns(T.untyped) }
        def self.build(execution_strategy); end

        # A list object must implement #each
        class CustomCollection
          sig { params(storage: T.untyped).returns(CustomCollection) }
          def initialize(storage); end

          sig { returns(T.untyped) }
          def each; end
        end

        module TestMiddleware
          sig do
            params(
              parent_type: T.untyped,
              parent_object: T.untyped,
              field_definition: T.untyped,
              field_args: T.untyped,
              query_context: T.untyped,
              next_middleware: T.untyped
            ).returns(T.untyped)
          end
          def self.call(parent_type, parent_object, field_definition, field_args, query_context, &next_middleware); end
        end
      end
    end

    # This asserts that a given parse function turns a string into
    # the proper tree of {{GraphQL::Language::Nodes}}.
    module QueryParserSpecification
      QUERY_STRING = T.let(%|
      query getStuff($someVar: Int = 1, $anotherVar: [String!] ) @skip(if: false) {
        myField: someField(someArg: $someVar, ok: 1.4) @skip(if: $anotherVar) @thing(or: "Whatever")

        anotherField(someArg: [1,2,3]) {
          nestedField
          ... moreNestedFields @skip(if: true)
        }

        ... on OtherType @include(unless: false){
          field(arg: [{key: "value", anotherKey: 0.9, anotherAnotherKey: WHATEVER}])
          anotherField
        }

        ... {
          id
        }
      }

      fragment moreNestedFields on NestedType @or(something: "ok") {
        anotherNestedField @enum(directive: true)
      }
|, T.untyped)

      # _@return_ — A test suite for this parse function
      sig { params(block: T.proc.params(query_string: String).returns(GraphQL::Language::Nodes::Document)).returns(T.untyped) }
      def self.build_suite(&block); end

      module QueryAssertions
        sig { params(query: T.untyped).returns(T.untyped) }
        def assert_valid_query(query); end

        sig { params(fragment_def: T.untyped).returns(T.untyped) }
        def assert_valid_fragment(fragment_def); end

        sig { params(variable: T.untyped).returns(T.untyped) }
        def assert_valid_variable(variable); end

        sig { params(field: T.untyped).returns(T.untyped) }
        def assert_valid_field(field); end

        sig { params(argument: T.untyped).returns(T.untyped) }
        def assert_valid_literal_argument(argument); end

        sig { params(argument: T.untyped).returns(T.untyped) }
        def assert_valid_variable_argument(argument); end

        sig { params(fragment_spread: T.untyped).returns(T.untyped) }
        def assert_valid_fragment_spread(fragment_spread); end

        sig { params(directive: T.untyped).returns(T.untyped) }
        def assert_valid_directive(directive); end

        sig { params(inline_fragment: T.untyped).returns(T.untyped) }
        def assert_valid_typed_inline_fragment(inline_fragment); end

        sig { params(inline_fragment: T.untyped).returns(T.untyped) }
        def assert_valid_typeless_inline_fragment(inline_fragment); end
      end

      module ParseErrorSpecification
        sig { params(query_string: T.untyped).returns(T.untyped) }
        def assert_raises_parse_error(query_string); end

        sig { returns(T.untyped) }
        def test_it_includes_line_and_column; end

        sig { returns(T.untyped) }
        def test_it_rejects_unterminated_strings; end

        sig { returns(T.untyped) }
        def test_it_rejects_unexpected_ends; end

        sig { params(char: T.untyped).returns(T.untyped) }
        def assert_rejects_character(char); end

        sig { returns(T.untyped) }
        def test_it_rejects_invalid_characters; end

        sig { returns(T.untyped) }
        def test_it_rejects_bad_unicode; end

        sig { returns(T.untyped) }
        def test_it_rejects_empty_inline_fragments; end

        sig { returns(T.untyped) }
        def test_it_rejects_blank_queries; end

        sig { returns(T.untyped) }
        def test_it_restricts_on; end
      end
    end

    # This asserts that a given parse function turns a string into
    # the proper tree of {{GraphQL::Language::Nodes}}.
    module SchemaParserSpecification
      SCHEMA_DEFINITION_STRING = T.let(%|
  # Schema at beginning of file

  schema {
    query: Hello
  }

  # Comment between two definitions are omitted

  # This is a directive
  directive @foo(
    # It has an argument
    arg: Int
  ) on FIELD

  # Multiline comment
  #
  # With an enum
  enum Color {
    RED

    # Not a creative color
    GREEN
    BLUE
  }

  #Comment without preceding space
  type Hello {
    # And a field to boot
    str: String
  }

  # Comment for input object types
  input Car {
    # Color of the car
    color: String!
  }

  # Comment for interface definitions
  interface Vehicle {
    # Amount of wheels
    wheels: Int!
    brand(argument: String = null): String!
  }

  # Comment at the end of schema
|, T.untyped)

      # _@return_ — A test suite for this parse function
      sig { params(block: T.proc.params(query_string: String).returns(GraphQL::Language::Nodes::Document)).returns(T.untyped) }
      def self.build_suite(&block); end
    end

    module LazyExecutionSpecification
      # _@param_ `execution_strategy` — An execution strategy class
      # 
      # _@return_ — A test suite for this execution strategy
      sig { params(execution_strategy: T::Array[T.any(T.untyped, T.untyped)]).returns(T.untyped) }
      def self.build_suite(execution_strategy); end

      module LazySchema
        sig { params(execution_strategy: T.untyped).returns(T.untyped) }
        def self.build(execution_strategy); end

        class LazyPush
          # Returns the value of attribute value
          sig { returns(T.untyped) }
          def value; end

          sig { params(ctx: T.untyped, value: T.untyped).returns(LazyPush) }
          def initialize(ctx, value); end

          sig { returns(T.untyped) }
          def push; end
        end

        class LazyPushCollection
          sig { params(ctx: T.untyped, values: T.untyped).returns(LazyPushCollection) }
          def initialize(ctx, values); end

          sig { returns(T.untyped) }
          def push; end

          sig { returns(T.untyped) }
          def value; end
        end

        module LazyInstrumentation
          sig { params(type: T.untyped, field: T.untyped).returns(T.untyped) }
          def self.instrument(type, field); end
        end
      end
    end
  end
end

module Graphql
  module Generators
    module Core
      sig { params(base: T.untyped).returns(T.untyped) }
      def self.included(base); end

      sig { params(type: T.untyped, name: T.untyped).returns(T.untyped) }
      def insert_root_type(type, name); end

      sig { returns(T.untyped) }
      def create_mutation_root_type; end

      sig { returns(T.untyped) }
      def schema_file_path; end

      sig { params(dir: T.untyped).returns(T.untyped) }
      def create_dir(dir); end

      sig { returns(T.untyped) }
      def schema_name; end
    end

    # Generate an enum type by name, with the given values.
    # To add a `value:` option, add another value after a `:`.
    # 
    # ```
    # rails g graphql:enum ProgrammingLanguage RUBY PYTHON PERL PERL6:"PERL"
    # ```
    class EnumGenerator < Graphql::Generators::TypeGeneratorBase
      sig { returns(T.untyped) }
      def create_type_file; end

      sig { returns(T.untyped) }
      def prepared_values; end
    end

    class TypeGeneratorBase < Rails::Generators::Base
      include Graphql::Generators::Core

      # Take a type expression in any combination of GraphQL or Ruby styles
      # and return it in a specified output style
      # TODO: nullability / list with `mode: :graphql` doesn't work
      # 
      # _@param_ `type_expresson` — 
      # 
      # _@param_ `mode` — 
      # 
      # _@param_ `null` — 
      # 
      # _@return_ — The type expression, followed by `null:` value
      sig { params(type_expression: T.untyped, mode: Symbol, null: T::Boolean).returns([String, T::Boolean]) }
      def self.normalize_type_expression(type_expression, mode:, null: true); end

      # _@return_ — The user-provided type name, normalized to Ruby code
      sig { returns(String) }
      def type_ruby_name; end

      # _@return_ — The user-provided type name, as a GraphQL name
      sig { returns(String) }
      def type_graphql_name; end

      # _@return_ — The user-provided type name, as a file name (without extension)
      sig { returns(String) }
      def type_file_name; end

      # _@return_ — User-provided fields, in `(name, Ruby type name)` pairs
      sig { returns(T::Array[NormalizedField]) }
      def normalized_fields; end

      sig { params(type: T.untyped, name: T.untyped).returns(T.untyped) }
      def insert_root_type(type, name); end

      sig { returns(T.untyped) }
      def create_mutation_root_type; end

      sig { returns(T.untyped) }
      def schema_file_path; end

      sig { params(dir: T.untyped).returns(T.untyped) }
      def create_dir(dir); end

      sig { returns(T.untyped) }
      def schema_name; end

      class NormalizedField
        sig { params(name: T.untyped, type_expr: T.untyped, null: T.untyped).returns(NormalizedField) }
        def initialize(name, type_expr, null); end

        sig { returns(T.untyped) }
        def to_ruby; end
      end
    end

    # Generate a union type by name
    # with the specified member types.
    # 
    # ```
    # rails g graphql:union SearchResultType ImageType AudioType
    # ```
    class UnionGenerator < Graphql::Generators::TypeGeneratorBase
      sig { returns(T.untyped) }
      def create_type_file; end

      sig { returns(T.untyped) }
      def normalized_possible_types; end
    end

    # @example Generate a `GraphQL::Batch` loader by name.
    #     rails g graphql:loader RecordLoader
    class LoaderGenerator < Rails::Generators::NamedBase
      include Graphql::Generators::Core

      sig { returns(T.untyped) }
      def create_loader_file; end

      sig { params(type: T.untyped, name: T.untyped).returns(T.untyped) }
      def insert_root_type(type, name); end

      sig { returns(T.untyped) }
      def create_mutation_root_type; end

      sig { returns(T.untyped) }
      def schema_file_path; end

      sig { params(dir: T.untyped).returns(T.untyped) }
      def create_dir(dir); end

      sig { returns(T.untyped) }
      def schema_name; end
    end

    # Generate an object type by name,
    # with the specified fields.
    # 
    # ```
    # rails g graphql:object PostType name:String!
    # ```
    # 
    # Add the Node interface with `--node`.
    class ObjectGenerator < Graphql::Generators::TypeGeneratorBase
      sig { returns(T.untyped) }
      def create_type_file; end
    end

    # Generate a scalar type by given name.
    # 
    # ```
    # rails g graphql:scalar Date
    # ```
    class ScalarGenerator < Graphql::Generators::TypeGeneratorBase
      sig { returns(T.untyped) }
      def create_type_file; end
    end

    # Add GraphQL to a Rails app with `rails g graphql:install`.
    # 
    # Setup a folder structure for GraphQL:
    # 
    # ```
    # - app/
    #   - graphql/
    #     - resolvers/
    #     - types/
    #       - base_argument.rb
    #       - base_field.rb
    #       - base_enum.rb
    #       - base_input_object.rb
    #       - base_interface.rb
    #       - base_object.rb
    #       - base_scalar.rb
    #       - base_union.rb
    #       - query_type.rb
    #     - loaders/
    #     - mutations/
    #     - {app_name}_schema.rb
    # ```
    # 
    # (Add `.gitkeep`s by default, support `--skip-keeps`)
    # 
    # Add a controller for serving GraphQL queries:
    # 
    # ```
    # app/controllers/graphql_controller.rb
    # ```
    # 
    # Add a route for that controller:
    # 
    # ```ruby
    # # config/routes.rb
    # post "/graphql", to: "graphql#execute"
    # ```
    # 
    # Accept a `--relay` option which adds
    # The root `node(id: ID!)` field.
    # 
    # Accept a `--batch` option which adds `GraphQL::Batch` setup.
    # 
    # Use `--no-graphiql` to skip `graphiql-rails` installation.
    # 
    # TODO: also add base classes
    class InstallGenerator < Rails::Generators::Base
      include Graphql::Generators::Core

      sig { returns(T.untyped) }
      def create_folder_structure; end

      sig { returns(T::Boolean) }
      def gemfile_modified?; end

      sig { params(args: T.untyped).returns(T.untyped) }
      def gem(*args); end

      sig { params(type: T.untyped, name: T.untyped).returns(T.untyped) }
      def insert_root_type(type, name); end

      sig { returns(T.untyped) }
      def create_mutation_root_type; end

      sig { returns(T.untyped) }
      def schema_file_path; end

      sig { params(dir: T.untyped).returns(T.untyped) }
      def create_dir(dir); end

      sig { returns(T.untyped) }
      def schema_name; end
    end

    # TODO: What other options should be supported?
    # 
    # @example Generate a `GraphQL::Schema::RelayClassicMutation` by name
    #     rails g graphql:mutation CreatePostMutation
    class MutationGenerator < Rails::Generators::Base
      include Graphql::Generators::Core

      # :nodoc:
      sig { params(args: T.untyped, options: T.untyped).returns(MutationGenerator) }
      def initialize(args, *options); end

      # Returns the value of attribute file_name
      sig { returns(T.untyped) }
      def file_name; end

      # Returns the value of attribute mutation_name
      sig { returns(T.untyped) }
      def mutation_name; end

      # Returns the value of attribute field_name
      sig { returns(T.untyped) }
      def field_name; end

      sig { returns(T.untyped) }
      def create_mutation_file; end

      sig { params(name: T.untyped).returns(T.untyped) }
      def assign_names!(name); end

      sig { params(type: T.untyped, name: T.untyped).returns(T.untyped) }
      def insert_root_type(type, name); end

      sig { returns(T.untyped) }
      def create_mutation_root_type; end

      sig { returns(T.untyped) }
      def schema_file_path; end

      sig { params(dir: T.untyped).returns(T.untyped) }
      def create_dir(dir); end

      sig { returns(T.untyped) }
      def schema_name; end
    end

    # Generate an interface type by name,
    # with the specified fields.
    # 
    # ```
    # rails g graphql:interface NamedEntityType name:String!
    # ```
    class InterfaceGenerator < Graphql::Generators::TypeGeneratorBase
      sig { returns(T.untyped) }
      def create_type_file; end
    end
  end
end

# backport from ruby v2.5 to v2.2 that has no `padding` things
# @api private
module Base64Bp
  extend Base64

  sig { params(bin: T.untyped, padding: T.untyped).returns(T.untyped) }
  def urlsafe_encode64(bin, padding:); end

  sig { params(bin: T.untyped, padding: T.untyped).returns(T.untyped) }
  def self.urlsafe_encode64(bin, padding:); end

  sig { params(str: T.untyped).returns(T.untyped) }
  def urlsafe_decode64(str); end

  sig { params(str: T.untyped).returns(T.untyped) }
  def self.urlsafe_decode64(str); end
end
