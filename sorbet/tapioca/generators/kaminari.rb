# typed: strict
# frozen_string_literal: true

begin
  require 'active_record'
  require 'kaminari'
rescue LoadError
  return
end

require "tapioca/compilers/dsl/helper/active_record_constants"

module Tapioca
  module Compilers
    module Dsl
      # Generator for kaminari gem.
      class Kaminari < Tapioca::Compilers::Dsl::Base
        extend T::Sig

        # TODO
        sig { override.params(tree: RBI::Tree, constant: Module).void }
        def decorate(tree, constant)
          # Get the configured Kaminari page method name, or fall back to 'page' if necessary.
          page_method = T.unsafe(::Kaminari).config.page_method_name || 'page'

          tree.create_path(constant) do |model|
            relation_model = model.create_module('GeneratedRelationMethods')
            relation_model.create_method(
              page_method.to_s,
              parameters: [
                create_opt_param('num', type: 'T.nilable(Integer)', default: 'nil')
              ],
              # TODO: Determine a better return type
              return_type: 'T.untyped'
            )

            relation_model.create_method(
              'per',
              parameters: [
                create_param('num', type: 'Integer'),
                create_opt_param('max_per_page', type: 'T.nilable(Integer)', default: 'nil')
              ],
              return_type: 'T.untyped'
            )
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          descendants_of(::ActiveRecord::Base).select do |klass|
            klass < ::Kaminari::ActiveRecordModelExtension && !klass.abstract_class?
          end
        end
      end
    end
  end
end
