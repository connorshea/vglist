# typed: strict
# frozen_string_literal: true

begin
  require 'active_record'
  require 'friendly_id'
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # Generator for friendly_id gem.
      class FriendlyId < Tapioca::Compilers::Dsl::Base
        extend T::Sig

        # Tell Tapioca about the extending of FriendlyId::Base, that way we
        # get the `friendly` method on any relevant models.
        sig { override.params(tree: RBI::Tree, constant: Module).void }
        def decorate(tree, constant)
          tree.create_path(constant) do |model|
            model.create_extend('FriendlyId::Base')
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          descendants_of(::ActiveRecord::Base).select do |klass|
            klass < ::FriendlyId::Model
          end
        end
      end
    end
  end
end
