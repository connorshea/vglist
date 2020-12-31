# typed: true
class PgSearchCustomPlugin < SorbetRails::ModelPlugins::Base
  # If you include GlobalSearchable or Searchable in a model, add `search`
  # class method.
  sig { override.params(root: Parlour::RbiGenerator::Namespace).void }
  def generate(root)
    return unless @model_class.include?(::GlobalSearchable) || @model_class.include?(::Searchable)

    model_rbi = root.create_class(
      model_class_name
    )

    model_rbi.create_method(
      'search',
      class_method: true,
      parameters: [
        ::Parlour::RbiGenerator::Parameter.new(
          '*args',
          type: 'T.untyped'
        )
      ],
      return_type: 'T.untyped'
    )
  end
end
