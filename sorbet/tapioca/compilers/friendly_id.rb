# typed: true

module Tapioca
  module Compilers
    class FriendlyId < Tapioca::Dsl::Compiler
      extend T::Sig

      ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

      sig { override.returns(T::Enumerable[Module]) }
      def self.gather_constants
        # Collect all the classes that include FriendlyId
        all_classes.select { |c| c.singleton_class.included_modules.include?(::FriendlyId) }
      end

      sig { override.void }
      def decorate
        root.create_path(constant) do |klass|
          common_relation_methods_module = klass.create_module('CommonRelationMethods')
          common_relation_methods_module.create_method(
            'friendly',
            parameters: [create_rest_param('args', type: 'T.untyped')],
            return_type: 'T.self_type'
          )
        end
      end
    end
  end
end
