# typed: true

module Tapioca
  module Compilers
    # This compiler will generate RBIs for all the helper modules in the repo.
    #
    # Rails creates these helper modules with no parent class, so Sorbet
    # doesn't know what should be included in them.
    #
    # This is based heavily on the Helpers RBI generator in the sorbet-rails
    # gem.
    class Helpers < Tapioca::Dsl::Compiler
      extend T::Sig

      ConstantType = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }

      sig { override.returns(T::Enumerable[Module]) }
      def self.gather_constants
        # API controller does not include ActionController::Helpers
        if ApplicationController < ActionController::Helpers
          helpers = ApplicationController.modules_for_helpers([:all])
        end

        # If ApplicationController doesn't work or doesn't return any helpers,
        # try using ActionController::Base.
        if ApplicationController < ActionController::Helpers && helpers.blank?
          helpers = ActionController::Base.modules_for_helpers([:all])
        end

        # Collect all helpers
        helpers
      end

      sig { override.void }
      def decorate
        root.create_path(constant) do |klass|
          # Default includes:
          klass.create_include('Kernel')
          klass.create_include('ActionView::Helpers')

          # Custom includes:
          klass.create_include('Devise::Controllers::Helpers')
        end
      end
    end
  end
end
