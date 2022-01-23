# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `ActiveStorage::Attachment`.
# Please instead update this file by running `bin/tapioca dsl ActiveStorage::Attachment`.

class ActiveStorage::Attachment
  include GeneratedAssociationMethods
  include GeneratedAttributeMethods
  extend CommonRelationMethods
  extend GeneratedRelationMethods

  private

  sig { returns(NilClass) }
  def to_ary; end

  module CommonRelationMethods
    sig { params(block: T.nilable(T.proc.params(record: ::ActiveStorage::Attachment).returns(T.untyped))).returns(T::Boolean) }
    def any?(&block); end

    sig { params(column_name: T.any(String, Symbol)).returns(T.untyped) }
    def average(column_name); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def build(attributes = nil, &block); end

    sig { params(operation: Symbol, column_name: T.any(String, Symbol)).returns(T.untyped) }
    def calculate(operation, column_name); end

    sig { params(column_name: T.untyped).returns(T.untyped) }
    def count(column_name = nil); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def create(attributes = nil, &block); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def create!(attributes = nil, &block); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def create_or_find_by(attributes, &block); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def create_or_find_by!(attributes, &block); end

    sig { returns(T::Array[::ActiveStorage::Attachment]) }
    def destroy_all; end

    sig { params(conditions: T.untyped).returns(T::Boolean) }
    def exists?(conditions = :none); end

    sig { returns(T.nilable(::ActiveStorage::Attachment)) }
    def fifth; end

    sig { returns(::ActiveStorage::Attachment) }
    def fifth!; end

    sig { params(args: T.untyped).returns(T.untyped) }
    def find(*args); end

    sig { params(args: T.untyped).returns(T.nilable(::ActiveStorage::Attachment)) }
    def find_by(*args); end

    sig { params(args: T.untyped).returns(::ActiveStorage::Attachment) }
    def find_by!(*args); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def find_or_create_by(attributes, &block); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def find_or_create_by!(attributes, &block); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def find_or_initialize_by(attributes, &block); end

    sig { params(limit: T.untyped).returns(T.untyped) }
    def first(limit = nil); end

    sig { returns(::ActiveStorage::Attachment) }
    def first!; end

    sig { returns(T.nilable(::ActiveStorage::Attachment)) }
    def forty_two; end

    sig { returns(::ActiveStorage::Attachment) }
    def forty_two!; end

    sig { returns(T.nilable(::ActiveStorage::Attachment)) }
    def fourth; end

    sig { returns(::ActiveStorage::Attachment) }
    def fourth!; end

    sig { returns(Array) }
    def ids; end

    sig { params(record: T.untyped).returns(T::Boolean) }
    def include?(record); end

    sig { params(limit: T.untyped).returns(T.untyped) }
    def last(limit = nil); end

    sig { returns(::ActiveStorage::Attachment) }
    def last!; end

    sig { params(block: T.nilable(T.proc.params(record: ::ActiveStorage::Attachment).returns(T.untyped))).returns(T::Boolean) }
    def many?(&block); end

    sig { params(column_name: T.any(String, Symbol)).returns(T.untyped) }
    def maximum(column_name); end

    sig { params(record: T.untyped).returns(T::Boolean) }
    def member?(record); end

    sig { params(column_name: T.any(String, Symbol)).returns(T.untyped) }
    def minimum(column_name); end

    sig { params(attributes: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Attachment).void)).returns(::ActiveStorage::Attachment) }
    def new(attributes = nil, &block); end

    sig { params(block: T.nilable(T.proc.params(record: ::ActiveStorage::Attachment).returns(T.untyped))).returns(T::Boolean) }
    def none?(&block); end

    sig { params(block: T.nilable(T.proc.params(record: ::ActiveStorage::Attachment).returns(T.untyped))).returns(T::Boolean) }
    def one?(&block); end

    sig { params(column_names: T.untyped).returns(T.untyped) }
    def pick(*column_names); end

    sig { params(column_names: T.untyped).returns(T.untyped) }
    def pluck(*column_names); end

    sig { returns(T.nilable(::ActiveStorage::Attachment)) }
    def second; end

    sig { returns(::ActiveStorage::Attachment) }
    def second!; end

    sig { returns(T.nilable(::ActiveStorage::Attachment)) }
    def second_to_last; end

    sig { returns(::ActiveStorage::Attachment) }
    def second_to_last!; end

    sig { params(column_name: T.nilable(T.any(String, Symbol)), block: T.nilable(T.proc.params(record: T.untyped).returns(T.untyped))).returns(T.untyped) }
    def sum(column_name = nil, &block); end

    sig { params(limit: T.untyped).returns(T.untyped) }
    def take(limit = nil); end

    sig { returns(::ActiveStorage::Attachment) }
    def take!; end

    sig { returns(T.nilable(::ActiveStorage::Attachment)) }
    def third; end

    sig { returns(::ActiveStorage::Attachment) }
    def third!; end

    sig { returns(T.nilable(::ActiveStorage::Attachment)) }
    def third_to_last; end

    sig { returns(::ActiveStorage::Attachment) }
    def third_to_last!; end
  end

  module GeneratedAssociationMethods
    sig { returns(T.nilable(::ActiveStorage::Blob)) }
    def blob; end

    sig { params(value: T.nilable(::ActiveStorage::Blob)).void }
    def blob=(value); end

    sig { params(args: T.untyped, blk: T.untyped).returns(::ActiveStorage::Blob) }
    def build_blob(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(::ActiveStorage::Blob) }
    def create_blob(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(::ActiveStorage::Blob) }
    def create_blob!(*args, &blk); end

    sig { returns(T.nilable(T.untyped)) }
    def record; end

    sig { params(value: T.nilable(T.untyped)).void }
    def record=(value); end

    sig { returns(T.nilable(::ActiveStorage::Blob)) }
    def reload_blob; end

    sig { returns(T.nilable(T.untyped)) }
    def reload_record; end
  end

  module GeneratedAssociationRelationMethods
    sig { returns(PrivateAssociationRelation) }
    def all; end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def and(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def annotate(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def create_with(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def distinct(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def eager_load(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def except(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def extending(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def extract_associated(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def from(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def group(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def having(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def includes(*args, &blk); end

    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
    def insert(attributes, returning: nil, unique_by: nil); end

    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass))).returns(ActiveRecord::Result) }
    def insert!(attributes, returning: nil); end

    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
    def insert_all(attributes, returning: nil, unique_by: nil); end

    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass))).returns(ActiveRecord::Result) }
    def insert_all!(attributes, returning: nil); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def joins(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def left_joins(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def left_outer_joins(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def limit(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def lock(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def merge(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def none(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def offset(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def only(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def optimizer_hints(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def or(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def order(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def preload(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def readonly(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def references(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def reorder(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def reselect(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def reverse_order(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def rewhere(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def select(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def strict_loading(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def uniq!(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelation) }
    def unscope(*args, &blk); end

    sig { params(attributes: Hash, returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
    def upsert(attributes, returning: nil, unique_by: nil); end

    sig { params(attributes: T::Array[Hash], returning: T.nilable(T.any(T::Array[Symbol], FalseClass)), unique_by: T.nilable(T.any(T::Array[Symbol], Symbol))).returns(ActiveRecord::Result) }
    def upsert_all(attributes, returning: nil, unique_by: nil); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateAssociationRelationWhereChain) }
    def where(*args, &blk); end
  end

  module GeneratedAttributeMethods
    sig { returns(::Integer) }
    def blob_id; end

    sig { params(value: ::Integer).returns(::Integer) }
    def blob_id=(value); end

    sig { returns(T::Boolean) }
    def blob_id?; end

    sig { returns(T.nilable(::Integer)) }
    def blob_id_before_last_save; end

    sig { returns(T.untyped) }
    def blob_id_before_type_cast; end

    sig { returns(T::Boolean) }
    def blob_id_came_from_user?; end

    sig { returns(T.nilable([::Integer, ::Integer])) }
    def blob_id_change; end

    sig { returns(T.nilable([::Integer, ::Integer])) }
    def blob_id_change_to_be_saved; end

    sig { returns(T::Boolean) }
    def blob_id_changed?; end

    sig { returns(T.nilable(::Integer)) }
    def blob_id_in_database; end

    sig { returns(T.nilable([::Integer, ::Integer])) }
    def blob_id_previous_change; end

    sig { returns(T::Boolean) }
    def blob_id_previously_changed?; end

    sig { returns(T.nilable(::Integer)) }
    def blob_id_previously_was; end

    sig { returns(T.nilable(::Integer)) }
    def blob_id_was; end

    sig { void }
    def blob_id_will_change!; end

    sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
    def created_at; end

    sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
    def created_at=(value); end

    sig { returns(T::Boolean) }
    def created_at?; end

    sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
    def created_at_before_last_save; end

    sig { returns(T.untyped) }
    def created_at_before_type_cast; end

    sig { returns(T::Boolean) }
    def created_at_came_from_user?; end

    sig { returns(T.nilable([T.nilable(::ActiveSupport::TimeWithZone), T.nilable(::ActiveSupport::TimeWithZone)])) }
    def created_at_change; end

    sig { returns(T.nilable([T.nilable(::ActiveSupport::TimeWithZone), T.nilable(::ActiveSupport::TimeWithZone)])) }
    def created_at_change_to_be_saved; end

    sig { returns(T::Boolean) }
    def created_at_changed?; end

    sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
    def created_at_in_database; end

    sig { returns(T.nilable([T.nilable(::ActiveSupport::TimeWithZone), T.nilable(::ActiveSupport::TimeWithZone)])) }
    def created_at_previous_change; end

    sig { returns(T::Boolean) }
    def created_at_previously_changed?; end

    sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
    def created_at_previously_was; end

    sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
    def created_at_was; end

    sig { void }
    def created_at_will_change!; end

    sig { returns(T.nilable(::Integer)) }
    def id; end

    sig { params(value: ::Integer).returns(::Integer) }
    def id=(value); end

    sig { returns(T::Boolean) }
    def id?; end

    sig { returns(T.nilable(::Integer)) }
    def id_before_last_save; end

    sig { returns(T.untyped) }
    def id_before_type_cast; end

    sig { returns(T::Boolean) }
    def id_came_from_user?; end

    sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
    def id_change; end

    sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
    def id_change_to_be_saved; end

    sig { returns(T::Boolean) }
    def id_changed?; end

    sig { returns(T.nilable(::Integer)) }
    def id_in_database; end

    sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
    def id_previous_change; end

    sig { returns(T::Boolean) }
    def id_previously_changed?; end

    sig { returns(T.nilable(::Integer)) }
    def id_previously_was; end

    sig { returns(T.nilable(::Integer)) }
    def id_was; end

    sig { void }
    def id_will_change!; end

    sig { returns(::String) }
    def name; end

    sig { params(value: ::String).returns(::String) }
    def name=(value); end

    sig { returns(T::Boolean) }
    def name?; end

    sig { returns(T.nilable(::String)) }
    def name_before_last_save; end

    sig { returns(T.untyped) }
    def name_before_type_cast; end

    sig { returns(T::Boolean) }
    def name_came_from_user?; end

    sig { returns(T.nilable([::String, ::String])) }
    def name_change; end

    sig { returns(T.nilable([::String, ::String])) }
    def name_change_to_be_saved; end

    sig { returns(T::Boolean) }
    def name_changed?; end

    sig { returns(T.nilable(::String)) }
    def name_in_database; end

    sig { returns(T.nilable([::String, ::String])) }
    def name_previous_change; end

    sig { returns(T::Boolean) }
    def name_previously_changed?; end

    sig { returns(T.nilable(::String)) }
    def name_previously_was; end

    sig { returns(T.nilable(::String)) }
    def name_was; end

    sig { void }
    def name_will_change!; end

    sig { returns(::Integer) }
    def record_id; end

    sig { params(value: ::Integer).returns(::Integer) }
    def record_id=(value); end

    sig { returns(T::Boolean) }
    def record_id?; end

    sig { returns(T.nilable(::Integer)) }
    def record_id_before_last_save; end

    sig { returns(T.untyped) }
    def record_id_before_type_cast; end

    sig { returns(T::Boolean) }
    def record_id_came_from_user?; end

    sig { returns(T.nilable([::Integer, ::Integer])) }
    def record_id_change; end

    sig { returns(T.nilable([::Integer, ::Integer])) }
    def record_id_change_to_be_saved; end

    sig { returns(T::Boolean) }
    def record_id_changed?; end

    sig { returns(T.nilable(::Integer)) }
    def record_id_in_database; end

    sig { returns(T.nilable([::Integer, ::Integer])) }
    def record_id_previous_change; end

    sig { returns(T::Boolean) }
    def record_id_previously_changed?; end

    sig { returns(T.nilable(::Integer)) }
    def record_id_previously_was; end

    sig { returns(T.nilable(::Integer)) }
    def record_id_was; end

    sig { void }
    def record_id_will_change!; end

    sig { returns(::String) }
    def record_type; end

    sig { params(value: ::String).returns(::String) }
    def record_type=(value); end

    sig { returns(T::Boolean) }
    def record_type?; end

    sig { returns(T.nilable(::String)) }
    def record_type_before_last_save; end

    sig { returns(T.untyped) }
    def record_type_before_type_cast; end

    sig { returns(T::Boolean) }
    def record_type_came_from_user?; end

    sig { returns(T.nilable([::String, ::String])) }
    def record_type_change; end

    sig { returns(T.nilable([::String, ::String])) }
    def record_type_change_to_be_saved; end

    sig { returns(T::Boolean) }
    def record_type_changed?; end

    sig { returns(T.nilable(::String)) }
    def record_type_in_database; end

    sig { returns(T.nilable([::String, ::String])) }
    def record_type_previous_change; end

    sig { returns(T::Boolean) }
    def record_type_previously_changed?; end

    sig { returns(T.nilable(::String)) }
    def record_type_previously_was; end

    sig { returns(T.nilable(::String)) }
    def record_type_was; end

    sig { void }
    def record_type_will_change!; end

    sig { void }
    def restore_blob_id!; end

    sig { void }
    def restore_created_at!; end

    sig { void }
    def restore_id!; end

    sig { void }
    def restore_name!; end

    sig { void }
    def restore_record_id!; end

    sig { void }
    def restore_record_type!; end

    sig { returns(T.nilable([::Integer, ::Integer])) }
    def saved_change_to_blob_id; end

    sig { returns(T::Boolean) }
    def saved_change_to_blob_id?; end

    sig { returns(T.nilable([T.nilable(::ActiveSupport::TimeWithZone), T.nilable(::ActiveSupport::TimeWithZone)])) }
    def saved_change_to_created_at; end

    sig { returns(T::Boolean) }
    def saved_change_to_created_at?; end

    sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
    def saved_change_to_id; end

    sig { returns(T::Boolean) }
    def saved_change_to_id?; end

    sig { returns(T.nilable([::String, ::String])) }
    def saved_change_to_name; end

    sig { returns(T::Boolean) }
    def saved_change_to_name?; end

    sig { returns(T.nilable([::Integer, ::Integer])) }
    def saved_change_to_record_id; end

    sig { returns(T::Boolean) }
    def saved_change_to_record_id?; end

    sig { returns(T.nilable([::String, ::String])) }
    def saved_change_to_record_type; end

    sig { returns(T::Boolean) }
    def saved_change_to_record_type?; end

    sig { returns(T::Boolean) }
    def will_save_change_to_blob_id?; end

    sig { returns(T::Boolean) }
    def will_save_change_to_created_at?; end

    sig { returns(T::Boolean) }
    def will_save_change_to_id?; end

    sig { returns(T::Boolean) }
    def will_save_change_to_name?; end

    sig { returns(T::Boolean) }
    def will_save_change_to_record_id?; end

    sig { returns(T::Boolean) }
    def will_save_change_to_record_type?; end
  end

  module GeneratedRelationMethods
    sig { returns(PrivateRelation) }
    def all; end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def and(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def annotate(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def create_with(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def distinct(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def eager_load(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def except(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def extending(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def extract_associated(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def from(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def group(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def having(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def includes(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def joins(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def left_joins(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def left_outer_joins(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def limit(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def lock(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def merge(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def none(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def offset(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def only(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def optimizer_hints(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def or(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def order(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def preload(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def readonly(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def references(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def reorder(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def reselect(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def reverse_order(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def rewhere(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def select(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def strict_loading(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def uniq!(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelation) }
    def unscope(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(PrivateRelationWhereChain) }
    def where(*args, &blk); end
  end

  class PrivateAssociationRelation < ::ActiveRecord::AssociationRelation
    include CommonRelationMethods
    include GeneratedAssociationRelationMethods

    sig { returns(T::Array[::ActiveStorage::Attachment]) }
    def to_ary; end

    Elem = type_member(fixed: ::ActiveStorage::Attachment)
  end

  class PrivateAssociationRelationWhereChain < PrivateAssociationRelation
    sig { params(args: T.untyped).returns(PrivateAssociationRelation) }
    def missing(*args); end

    sig { params(opts: T.untyped, rest: T.untyped).returns(PrivateAssociationRelation) }
    def not(opts, *rest); end

    Elem = type_member(fixed: ::ActiveStorage::Attachment)
  end

  class PrivateCollectionProxy < ::ActiveRecord::Associations::CollectionProxy
    include CommonRelationMethods
    include GeneratedAssociationRelationMethods

    sig { params(records: T.any(::ActiveStorage::Attachment, T::Enumerable[T.any(::ActiveStorage::Attachment, T::Enumerable[::ActiveStorage::Attachment])])).returns(PrivateCollectionProxy) }
    def <<(*records); end

    sig { params(records: T.any(::ActiveStorage::Attachment, T::Enumerable[T.any(::ActiveStorage::Attachment, T::Enumerable[::ActiveStorage::Attachment])])).returns(PrivateCollectionProxy) }
    def append(*records); end

    sig { returns(PrivateCollectionProxy) }
    def clear; end

    sig { params(records: T.any(::ActiveStorage::Attachment, T::Enumerable[T.any(::ActiveStorage::Attachment, T::Enumerable[::ActiveStorage::Attachment])])).returns(PrivateCollectionProxy) }
    def concat(*records); end

    sig { params(records: T.any(::ActiveStorage::Attachment, Integer, String, T::Enumerable[T.any(::ActiveStorage::Attachment, Integer, String, T::Enumerable[::ActiveStorage::Attachment])])).returns(T::Array[::ActiveStorage::Attachment]) }
    def delete(*records); end

    sig { params(records: T.any(::ActiveStorage::Attachment, Integer, String, T::Enumerable[T.any(::ActiveStorage::Attachment, Integer, String, T::Enumerable[::ActiveStorage::Attachment])])).returns(T::Array[::ActiveStorage::Attachment]) }
    def destroy(*records); end

    sig { returns(T::Array[::ActiveStorage::Attachment]) }
    def load_target; end

    sig { params(records: T.any(::ActiveStorage::Attachment, T::Enumerable[T.any(::ActiveStorage::Attachment, T::Enumerable[::ActiveStorage::Attachment])])).returns(PrivateCollectionProxy) }
    def prepend(*records); end

    sig { params(records: T.any(::ActiveStorage::Attachment, T::Enumerable[T.any(::ActiveStorage::Attachment, T::Enumerable[::ActiveStorage::Attachment])])).returns(PrivateCollectionProxy) }
    def push(*records); end

    sig { params(other_array: T.any(::ActiveStorage::Attachment, T::Enumerable[T.any(::ActiveStorage::Attachment, T::Enumerable[::ActiveStorage::Attachment])])).returns(T::Array[::ActiveStorage::Attachment]) }
    def replace(other_array); end

    sig { returns(PrivateAssociationRelation) }
    def scope; end

    sig { returns(T::Array[::ActiveStorage::Attachment]) }
    def target; end

    sig { returns(T::Array[::ActiveStorage::Attachment]) }
    def to_ary; end

    Elem = type_member(fixed: ::ActiveStorage::Attachment)
  end

  class PrivateRelation < ::ActiveRecord::Relation
    include CommonRelationMethods
    include GeneratedRelationMethods

    sig { returns(T::Array[::ActiveStorage::Attachment]) }
    def to_ary; end

    Elem = type_member(fixed: ::ActiveStorage::Attachment)
  end

  class PrivateRelationWhereChain < PrivateRelation
    sig { params(args: T.untyped).returns(PrivateRelation) }
    def missing(*args); end

    sig { params(opts: T.untyped, rest: T.untyped).returns(PrivateRelation) }
    def not(opts, *rest); end

    Elem = type_member(fixed: ::ActiveStorage::Attachment)
  end
end
