# typed: true

module Tapioca
  module Compilers
    class PgSearch < Tapioca::Dsl::Compiler
      extend T::Sig

      ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

      sig { override.returns(T::Enumerable[Module]) }
      def self.gather_constants
        # Collect all the classes that include Encryptable
        all_classes.select { |c| c < ::GlobalSearchable || c < ::Searchable }
      end

      sig { override.void }
      def decorate
        # Create a RBI definition for each class that includes Searchable or GlobalSearchable
        root.create_path(constant) do |klass|
          klass.create_method(
            'search',
            parameters: [create_rest_param('args', type: 'T.untyped')],
            return_type: 'T.untyped',
            class_method: true
          )
        end
      end
    end
  end
end
