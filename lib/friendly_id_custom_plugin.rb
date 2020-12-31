# typed: true
class FriendlyIdCustomPlugin < SorbetRails::ModelPlugins::Base
  # If you include FriendlyId in a model, add `search`
  # class method.
  sig { override.params(root: Parlour::RbiGenerator::Namespace).void }
  def generate(root)
    return unless @model_class.include?(::FriendlyId::Model)

    model_rbi = root.create_class(
      model_class_name
    )

    model_rbi.create_extend('FriendlyId::Base')
  end
end
