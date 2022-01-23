# typed: strict
# frozen_string_literal: true

begin
  require 'active_record'
  require 'pg_search'
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # Generator for pg_search gem.
      # If you include GlobalSearchable or Searchable in a model, add the
      # `search` class method.
      class PgSearch < Tapioca::Compilers::Dsl::Base
        extend T::Sig

        sig { override.params(tree: RBI::Tree, constant: Module).void }
        def decorate(tree, constant)
          tree.create_path(constant) do |model|
            model.create_method(
              'search',
              class_method: true,
              parameters: [
                create_rest_param("args", type: "T.untyped")
              ],
              return_type: "#{constant}::PrivateRelation"
            )
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          descendants_of(::ActiveRecord::Base).select do |klass|
            klass < ::GlobalSearchable || klass < ::Searchable
          end
        end
      end
    end
  end
end
