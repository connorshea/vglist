# typed: true
class FriendlyIdRbiPlugin < SorbetRails::ModelPlugins::Base
  sig { params(root: Parlour::RbiGenerator::Namespace).void.implementation }
  def generate(root)
    return unless @model_class.singleton_class.included_modules.include?(FriendlyId)

    model_rbi = root.create_class(
      model_class_name,
      superclass: 'ApplicationRecord'
    )

    model_rbi.create_method(
      'friendly',
      parameters: [
        Parlour::RbiGenerator::Parameter.new('*args', type: 'T.untyped')
      ],
      return_type: model_relation_class_name,
      class_method: true
    )
  end
end
