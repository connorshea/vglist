# typed: true

module Tapioca
  module Compilers
    class Kaminari < Tapioca::Dsl::Compiler
      extend T::Sig

      ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

      sig { override.returns(T::Enumerable[Module]) }
      def self.gather_constants
        # Collect all the classes that include Kaminari
        all_classes.select { |c| c < ::Kaminari::ActiveRecordModelExtension }
      end

      sig { override.void }
      def decorate
        # Get the configured Kaminari page method name, or fall back to 'page' if necessary.
        page_method = T.unsafe(::Kaminari).config.page_method_name || 'page'

        root.create_path(constant) do |klass|
          klass.create_module('GeneratedRelationMethods').create_method(
            page_method.to_s,
            parameters: [create_opt_param('num', type: 'T.nilable(Integer)', default: 'nil')],
            return_type: 'PrivateRelation'
          )
        end
      end
    end
  end
end
