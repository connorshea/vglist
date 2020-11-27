# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `active_storage_validations` gem.
# Please instead update this file by running `tapioca sync`.

# typed: true

module ActiveStorageValidations
end

class ActiveStorageValidations::AspectRatioValidator < ::ActiveModel::EachValidator
  def initialize(options); end

  def check_validity!; end
  def validate_each(record, attribute, _value); end

  private

  def add_error(record, attribute, type, interpolate = T.unsafe(nil)); end
  def is_valid?(record, attribute, metadata); end
end

ActiveStorageValidations::AspectRatioValidator::AVAILABLE_CHECKS = T.let(T.unsafe(nil), Array)

ActiveStorageValidations::AspectRatioValidator::PRECISION = T.let(T.unsafe(nil), Integer)

class ActiveStorageValidations::AttachedValidator < ::ActiveModel::EachValidator
  def validate_each(record, attribute, _value); end
end

class ActiveStorageValidations::ContentTypeValidator < ::ActiveModel::EachValidator
  def content_type(file); end
  def is_valid?(file); end
  def types; end
  def types_to_human_format; end
  def validate_each(record, attribute, _value); end
end

class ActiveStorageValidations::DimensionValidator < ::ActiveModel::EachValidator
  def initialize(options); end

  def add_error(record, attribute, type, *attrs); end
  def check_validity!; end
  def is_valid?(record, attribute, file_metadata); end
  def validate_each(record, attribute, _value); end
end

ActiveStorageValidations::DimensionValidator::AVAILABLE_CHECKS = T.let(T.unsafe(nil), Array)

class ActiveStorageValidations::Engine < ::Rails::Engine
end

class ActiveStorageValidations::LimitValidator < ::ActiveModel::EachValidator
  def check_validity!; end
  def files_count_valid?(count); end
  def validate_each(record, attribute, _); end
end

ActiveStorageValidations::LimitValidator::AVAILABLE_CHECKS = T.let(T.unsafe(nil), Array)

module ActiveStorageValidations::Matchers
  def validate_attached_of(name); end
  def validate_content_type_of(name); end
  def validate_dimensions_of(name); end
  def validate_size_of(name); end

  class << self
    def mock_metadata(attachment, width, height); end
    def stub_method(object, method, result); end
  end
end

class ActiveStorageValidations::Matchers::AttachedValidatorMatcher
  def initialize(attribute_name); end

  def description; end
  def failure_message; end
  def failure_message_when_negated; end
  def matches?(subject); end

  private

  def attachable; end
  def invalid_when_not_attached; end
  def valid_when_attached; end
end

class ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher
  def initialize(attribute_name); end

  def allowing(*types); end
  def description; end
  def failure_message; end
  def matches?(subject); end
  def rejecting(*types); end

  protected

  def accepted_types_and_failures; end
  def allowed_types; end
  def allowed_types_allowed?; end
  def attachment_for(type); end
  def rejected_types; end
  def rejected_types_and_failures; end
  def rejected_types_rejected?; end
  def type_allowed?(type); end
end

class ActiveStorageValidations::Matchers::DimensionValidatorMatcher
  def initialize(attribute_name); end

  def description; end
  def failure_message; end
  def height(height); end
  def height_between(range); end
  def height_max(height); end
  def height_min(height); end
  def matches?(subject); end
  def width(width); end
  def width_between(range); end
  def width_max(width); end
  def width_min(width); end

  protected

  def attachment_for(width, height); end
  def height_equals?; end
  def height_larger_than_max?; end
  def height_larger_than_min?; end
  def height_smaller_than_max?; end
  def height_smaller_than_min?; end
  def passes_validation_with_dimensions(width, height, check); end
  def valid_height; end
  def valid_width; end
  def width_equals?; end
  def width_larger_than_max?; end
  def width_larger_than_min?; end
  def width_smaller_than_max?; end
  def width_smaller_than_min?; end
end

class ActiveStorageValidations::Matchers::SizeValidatorMatcher
  def initialize(attribute_name); end

  def between(range); end
  def description; end
  def failure_message; end
  def failure_message_when_negated; end
  def greater_than(size); end
  def greater_than_or_equal_to(size); end
  def less_than(size); end
  def less_than_or_equal_to(size); end
  def matches?(subject); end

  protected

  def higher_than_high?; end
  def higher_than_low?; end
  def lower_than_high?; end
  def lower_than_low?; end
  def passes_validation_with_size(new_size); end
end

class ActiveStorageValidations::Metadata
  def initialize(file); end

  def file; end
  def metadata; end

  private

  def logger; end
  def read_file_path; end
  def read_image; end
  def rotated_image?(image); end
end

class ActiveStorageValidations::Railtie < ::Rails::Railtie
end

class ActiveStorageValidations::SizeValidator < ::ActiveModel::EachValidator
  def check_validity!; end
  def content_size_valid?(file_size); end
  def number_to_human_size(*args, &block); end
  def validate_each(record, attribute, _value); end
end

ActiveStorageValidations::SizeValidator::AVAILABLE_CHECKS = T.let(T.unsafe(nil), Array)
