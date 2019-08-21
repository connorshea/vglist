# typed: true
class CursedRbiPlugin < SorbetRails::ModelPlugins::Base
  # Add some cursed methods to the Rails generators.
  def generate(root)
    return unless @model_class.reflections.length > 0
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
        # def build_user(*args, &block); end
        assoc_module_rbi.create_method(
          "build_#{assoc_name}",
          parameters: [
            Parlour::RbiGenerator::Parameter.new("*args", type: 'T.untyped'),
            Parlour::RbiGenerator::Parameter.new("&block", type: 'T.untyped')
          ],
          return_type: 'T.untyped'
        )
        # def create_user(*args, &block); end
        assoc_module_rbi.create_method(
          "create_#{assoc_name}",
          parameters: [
            Parlour::RbiGenerator::Parameter.new("*args", type: 'T.untyped'),
            Parlour::RbiGenerator::Parameter.new("&block", type: 'T.untyped')
          ],
          return_type: 'T.untyped'
        )
        # def create_user!(*args, &block); end
        assoc_module_rbi.create_method(
          "create_#{assoc_name}!",
          parameters: [
            Parlour::RbiGenerator::Parameter.new("*args", type: 'T.untyped'),
            Parlour::RbiGenerator::Parameter.new("&block", type: 'T.untyped')
          ],
          return_type: 'T.untyped'
        )
        # def reload_user(); end
        assoc_module_rbi.create_method(
          "reload_#{assoc_name}",
          return_type: 'T.untyped'
        )
      end

      if has_many_through_reflections.include?(reflection.class)
        # def user_ids(); end
        assoc_module_rbi.create_method(
          "#{assoc_name.to_s.singularize}_ids",
          return_type: 'T.untyped'
        )

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
    end
  end

  # Create "(after/before)_(add/remove)_for_#{assoc_name}" methods
  def create_after_before_add_remove_methods(assoc_name, model_klass)
    prefixes = [
      'after_add_for_',
      'after_remove_for_',
      'before_add_for_',
      'before_remove_for_'
    ]

    # This should also create separate class and instance methods, but
    # currently Parlour doesn't like when you do that.
    prefixes.each do |prefix|
      # def after_add_for_author(); end
      model_klass.create_method(
        "#{prefix}#{assoc_name}",
        return_type: 'T.untyped'
      )
      # def after_add_for_author?(); end
      model_klass.create_method(
        "#{prefix}#{assoc_name}?",
        return_type: 'T.untyped'
      )
      # def after_add_for_author=(val); end
      model_klass.create_method(
        "#{prefix}#{assoc_name}=",
        parameters: [
          Parlour::RbiGenerator::Parameter.new('val', type: 'T.untyped')
        ],
        return_type: 'T.untyped'
      )
    end
  end

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
end
