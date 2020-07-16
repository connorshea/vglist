# typed: true
class CursedRbiPlugin < SorbetRails::ModelPlugins::Base
  # Add some cursed methods to the Rails generators.
  sig { override.params(root: Parlour::RbiGenerator::Namespace).void }
  def generate(root)
    return if @model_class.reflections.keys.empty?

    assoc_module_name = model_module_name("GeneratedAssociationMethods")
    assoc_module_rbi = root.create_module(assoc_module_name)

    singular_associations = [
      ActiveRecord::Reflection::HasOneReflection,
      ActiveRecord::Reflection::BelongsToReflection
    ]

    has_many_through_reflections = [
      ActiveRecord::Reflection::HasManyReflection,
      ActiveRecord::Reflection::ThroughReflection
    ]

    @model_class.reflections.each do |assoc_name, reflection|
      # puts "assoc_name: #{assoc_name}, reflection: #{reflection}"
      if singular_associations.include?(reflection.class)
        # def reload_user(); end
        assoc_module_rbi.create_method(
          "reload_#{assoc_name}",
          return_type: 'T.untyped'
        )
      end

      if has_many_through_reflections.include?(reflection.class)
        # def user_ids=(ids); end
        assoc_module_rbi.create_method(
          "#{assoc_name.to_s.singularize}_ids=",
          parameters: [
            Parlour::RbiGenerator::Parameter.new("ids", type: 'T.untyped')
          ],
          return_type: 'T.untyped'
        )

        model_klass = root.create_class(model_class_name)
        create_after_before_add_remove_methods(assoc_name, model_klass)
      end

      all_the_reflections = has_many_through_reflections.concat(singular_associations)
      if all_the_reflections.include?(reflection.class)
        model_klass = root.create_class(model_class_name)
        autosave_and_validate_associated_records_methods(assoc_name, model_klass)
      end

      # Generate the methods for GeneratedAttributeMethods.
      model_generated_attribute_methods = root.create_module(model_module_name("GeneratedAttributeMethods"))
      @model_class.attribute_names.each do |attribute|
        dirty_methods(attribute, model_generated_attribute_methods)
      end
    end
  end

  # Create "(after/before)_(add/remove)_for_#{assoc_name}" methods
  sig { params(assoc_name: String, model_klass: T.any(Parlour::RbiGenerator::ClassNamespace, Parlour::RbiGenerator::ModuleNamespace)).void }
  def create_after_before_add_remove_methods(assoc_name, model_klass)
    prefixes = [
      'after_add_for_',
      'after_remove_for_',
      'before_add_for_',
      'before_remove_for_'
    ]

    # Create separate class and instance methods since Rails has them... for some reason.
    [true, false].each do |bool|
      prefixes.each do |prefix|
        # def after_add_for_author(); end
        model_klass.create_method(
          "#{prefix}#{assoc_name}",
          return_type: 'T.untyped',
          class_method: bool
        )
        # def after_add_for_author?(); end
        model_klass.create_method(
          "#{prefix}#{assoc_name}?",
          return_type: 'T::Boolean',
          class_method: bool
        )
        # def after_add_for_author=(val); end
        model_klass.create_method(
          "#{prefix}#{assoc_name}=",
          parameters: [
            Parlour::RbiGenerator::Parameter.new('val', type: 'T.untyped')
          ],
          return_type: 'T.untyped',
          class_method: bool
        )
      end
    end
  end

  sig { params(assoc_name: String, model_klass: T.any(Parlour::RbiGenerator::ClassNamespace, Parlour::RbiGenerator::ModuleNamespace)).void }
  def autosave_and_validate_associated_records_methods(assoc_name, model_klass)
    # def autosave_associated_records_for_developers(*args); end
    model_klass.create_method(
      "autosave_associated_records_for_#{assoc_name}",
      parameters: [
        Parlour::RbiGenerator::Parameter.new('*args', type: 'T.untyped')
      ],
      return_type: 'T.untyped'
    )

    # def validate_associated_records_for_developers(*args); end
    model_klass.create_method(
      "validate_associated_records_for_#{assoc_name}",
      parameters: [
        Parlour::RbiGenerator::Parameter.new('*args', type: 'T.untyped')
      ],
      return_type: 'T.untyped'
    )
  end

  sig { params(attribute_name: String, model_klass: T.any(Parlour::RbiGenerator::ClassNamespace, Parlour::RbiGenerator::ModuleNamespace)).void }
  def dirty_methods(attribute_name, model_klass)
    methods = [
      "saved_change_to_#{attribute_name}?",
      "saved_change_to_#{attribute_name}",
      "#{attribute_name}_before_last_save",
      "will_save_change_to_#{attribute_name}?",
      "#{attribute_name}_change_to_be_saved",
      "#{attribute_name}_in_database",
      "#{attribute_name}_changed?",
      "#{attribute_name}_change",
      "#{attribute_name}_will_change!",
      "#{attribute_name}_was",
      "#{attribute_name}_previously_changed?",
      "#{attribute_name}_previous_change",
      "restore_#{attribute_name}!",
      # technically these two aren't from ActiveModel::Dirty, but whatever.
      "#{attribute_name}_before_type_cast",
      "#{attribute_name}_came_from_user?"
    ]

    methods.each do |meth|
      return_type = meth.end_with?('?') ? 'T::Boolean' : 'T.untyped'
      model_klass.create_method(
        meth,
        parameters: [
          Parlour::RbiGenerator::Parameter.new('*args', type: 'T.untyped')
        ],
        return_type: return_type
      )
    end
  end
end
