# This is an autogenerated file for dynamic methods in ActiveStorage::Attachment
# Please rerun bundle exec rake rails_rbi:models[ActiveStorage::Attachment] to regenerate.

# typed: strong
module ActiveStorage::Attachment::ActiveRelation_WhereNot
  sig { params(opts: T.untyped, rest: T.untyped).returns(T.self_type) }
  def not(opts, *rest); end
end

module ActiveStorage::Attachment::CustomFinderMethods
  sig { params(limit: Integer).returns(T::Array[ActiveStorage::Attachment]) }
  def first_n(limit); end

  sig { params(limit: Integer).returns(T::Array[ActiveStorage::Attachment]) }
  def last_n(limit); end

  sig { params(args: T::Array[T.any(Integer, String)]).returns(T::Array[ActiveStorage::Attachment]) }
  def find_n(*args); end

  sig { params(id: Integer).returns(T.nilable(ActiveStorage::Attachment)) }
  def find_by_id(id); end

  sig { params(id: Integer).returns(ActiveStorage::Attachment) }
  def find_by_id!(id); end
end

class ActiveStorage::Attachment < ActiveStorage::Record
  include ActiveStorage::Attachment::GeneratedAttributeMethods
  include ActiveStorage::Attachment::GeneratedAssociationMethods
  extend ActiveStorage::Attachment::CustomFinderMethods
  extend ActiveStorage::Attachment::QueryMethodsReturningRelation
  RelationType = T.type_alias { T.any(ActiveStorage::Attachment::ActiveRecord_Relation, ActiveStorage::Attachment::ActiveRecord_Associations_CollectionProxy, ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }

  sig { params(args: T.untyped).returns(T.untyped) }
  def autosave_associated_records_for_record(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def validate_associated_records_for_record(*args); end

  sig { returns(T.untyped) }
  def self.after_add_for_blob; end

  sig { returns(T::Boolean) }
  def self.after_add_for_blob?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def self.after_add_for_blob=(val); end

  sig { returns(T.untyped) }
  def self.after_remove_for_blob; end

  sig { returns(T::Boolean) }
  def self.after_remove_for_blob?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def self.after_remove_for_blob=(val); end

  sig { returns(T.untyped) }
  def self.before_add_for_blob; end

  sig { returns(T::Boolean) }
  def self.before_add_for_blob?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def self.before_add_for_blob=(val); end

  sig { returns(T.untyped) }
  def self.before_remove_for_blob; end

  sig { returns(T::Boolean) }
  def self.before_remove_for_blob?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def self.before_remove_for_blob=(val); end

  sig { returns(T.untyped) }
  def after_add_for_blob; end

  sig { returns(T::Boolean) }
  def after_add_for_blob?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def after_add_for_blob=(val); end

  sig { returns(T.untyped) }
  def after_remove_for_blob; end

  sig { returns(T::Boolean) }
  def after_remove_for_blob?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def after_remove_for_blob=(val); end

  sig { returns(T.untyped) }
  def before_add_for_blob; end

  sig { returns(T::Boolean) }
  def before_add_for_blob?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def before_add_for_blob=(val); end

  sig { returns(T.untyped) }
  def before_remove_for_blob; end

  sig { returns(T::Boolean) }
  def before_remove_for_blob?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def before_remove_for_blob=(val); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def autosave_associated_records_for_blob(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def validate_associated_records_for_blob(*args); end

  sig { params(num: T.nilable(Integer)).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def self.page(num = nil); end

  sig { params(num: Integer, max_per_page: T.nilable(Integer)).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def self.per(num, max_per_page = nil); end

  sig { params(num: Integer).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def self.padding(num); end

  sig { returns(Integer) }
  def self.default_per_page; end
end

module ActiveStorage::Attachment::QueryMethodsReturningRelation
  sig { returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def all; end

  sig { params(block: T.nilable(T.proc.void)).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def unscoped(&block); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def select(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def reselect(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def order(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def reorder(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def group(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def limit(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def offset(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def joins(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def left_joins(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def left_outer_joins(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def where(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def rewhere(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def preload(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def extract_associated(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def eager_load(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def includes(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def from(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def lock(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def readonly(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def or(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def having(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def create_with(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def distinct(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def references(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def none(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def unscope(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def optimizer_hints(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def merge(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def except(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def only(*args); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def extending(*args, &block); end

  sig do
    params(
      of: T.nilable(Integer),
      start: T.nilable(Integer),
      finish: T.nilable(Integer),
      load: T.nilable(T::Boolean),
      error_on_ignore: T.nilable(T::Boolean),
      block: T.nilable(T.proc.params(e: ActiveStorage::Attachment::ActiveRecord_Relation).void)
    ).returns(ActiveRecord::Batches::BatchEnumerator)
  end
  def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, &block); end
end

module ActiveStorage::Attachment::QueryMethodsReturningAssociationRelation
  sig { returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def all; end

  sig { params(block: T.nilable(T.proc.void)).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def unscoped(&block); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def select(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def reselect(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def order(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def reorder(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def group(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def limit(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def offset(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def joins(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def left_joins(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def left_outer_joins(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def where(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def rewhere(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def preload(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def extract_associated(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def eager_load(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def includes(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def from(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def lock(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def readonly(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def or(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def having(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def create_with(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def distinct(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def references(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def none(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def unscope(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def optimizer_hints(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def merge(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def except(*args); end

  sig { params(args: T.untyped).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def only(*args); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def extending(*args, &block); end

  sig do
    params(
      of: T.nilable(Integer),
      start: T.nilable(Integer),
      finish: T.nilable(Integer),
      load: T.nilable(T::Boolean),
      error_on_ignore: T.nilable(T::Boolean),
      block: T.nilable(T.proc.params(e: ActiveStorage::Attachment::ActiveRecord_AssociationRelation).void)
    ).returns(ActiveRecord::Batches::BatchEnumerator)
  end
  def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, &block); end
end

class ActiveStorage::Attachment::ActiveRecord_Relation < ActiveRecord::Relation
  include ActiveStorage::Attachment::ActiveRelation_WhereNot
  include ActiveStorage::Attachment::CustomFinderMethods
  include ActiveStorage::Attachment::QueryMethodsReturningRelation
  Elem = type_member(fixed: ActiveStorage::Attachment)

  sig { params(num: T.nilable(Integer)).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def page(num = nil); end

  sig { params(num: Integer, max_per_page: T.nilable(Integer)).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def per(num, max_per_page = nil); end

  sig { params(num: Integer).returns(ActiveStorage::Attachment::ActiveRecord_Relation) }
  def padding(num); end
end

class ActiveStorage::Attachment::ActiveRecord_AssociationRelation < ActiveRecord::AssociationRelation
  include ActiveStorage::Attachment::ActiveRelation_WhereNot
  include ActiveStorage::Attachment::CustomFinderMethods
  include ActiveStorage::Attachment::QueryMethodsReturningAssociationRelation
  Elem = type_member(fixed: ActiveStorage::Attachment)

  sig { params(num: T.nilable(Integer)).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def page(num = nil); end

  sig { params(num: Integer, max_per_page: T.nilable(Integer)).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def per(num, max_per_page = nil); end

  sig { params(num: Integer).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def padding(num); end
end

module ActiveStorage::Attachment::GeneratedAttributeMethods
  sig { returns(Integer) }
  def blob_id; end

  sig { params(value: T.any(Numeric, ActiveSupport::Duration)).void }
  def blob_id=(value); end

  sig { returns(T::Boolean) }
  def blob_id?; end

  sig { returns(ActiveSupport::TimeWithZone) }
  def created_at; end

  sig { params(value: T.any(Date, Time, ActiveSupport::TimeWithZone)).void }
  def created_at=(value); end

  sig { returns(T::Boolean) }
  def created_at?; end

  sig { returns(Integer) }
  def id; end

  sig { params(value: T.any(Numeric, ActiveSupport::Duration)).void }
  def id=(value); end

  sig { returns(T::Boolean) }
  def id?; end

  sig { returns(String) }
  def name; end

  sig { params(value: T.any(String, Symbol)).void }
  def name=(value); end

  sig { returns(T::Boolean) }
  def name?; end

  sig { returns(Integer) }
  def record_id; end

  sig { params(value: T.any(Numeric, ActiveSupport::Duration)).void }
  def record_id=(value); end

  sig { returns(T::Boolean) }
  def record_id?; end

  sig { returns(String) }
  def record_type; end

  sig { params(value: T.any(String, Symbol)).void }
  def record_type=(value); end

  sig { returns(T::Boolean) }
  def record_type?; end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def saved_change_to_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_id(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def id_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def id_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def id_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def id_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def id_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def id_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def id_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def id_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def id_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_id!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def id_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def id_came_from_user?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def saved_change_to_name?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_name(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def name_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_name?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def name_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def name_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def name_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def name_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def name_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def name_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def name_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def name_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_name!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def name_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def name_came_from_user?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def saved_change_to_record_type?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_record_type(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_type_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_record_type?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_type_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_type_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def record_type_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_type_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_type_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_type_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def record_type_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_type_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_record_type!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_type_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def record_type_came_from_user?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def saved_change_to_record_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_record_id(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_id_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_record_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_id_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_id_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def record_id_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_id_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_id_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_id_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def record_id_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_id_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_record_id!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def record_id_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def record_id_came_from_user?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def saved_change_to_blob_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_blob_id(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def blob_id_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_blob_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def blob_id_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def blob_id_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def blob_id_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def blob_id_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def blob_id_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def blob_id_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def blob_id_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def blob_id_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_blob_id!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def blob_id_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def blob_id_came_from_user?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def saved_change_to_created_at?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_created_at(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def created_at_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_created_at?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def created_at_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def created_at_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def created_at_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def created_at_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def created_at_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def created_at_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def created_at_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def created_at_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_created_at!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def created_at_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def created_at_came_from_user?(*args); end
end

module ActiveStorage::Attachment::GeneratedAssociationMethods
  sig { returns(::ActiveStorage::Blob) }
  def blob; end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Blob).void)).returns(::ActiveStorage::Blob) }
  def build_blob(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Blob).void)).returns(::ActiveStorage::Blob) }
  def create_blob(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::ActiveStorage::Blob).void)).returns(::ActiveStorage::Blob) }
  def create_blob!(*args, &block); end

  sig { params(value: ::ActiveStorage::Blob).void }
  def blob=(value); end

  sig { returns(T.untyped) }
  def record; end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: T.untyped).void)).returns(T.untyped) }
  def build_record(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: T.untyped).void)).returns(T.untyped) }
  def create_record(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: T.untyped).void)).returns(T.untyped) }
  def create_record!(*args, &block); end

  sig { params(value: T.untyped).void }
  def record=(value); end

  sig { returns(T.untyped) }
  def reload_record; end

  sig { returns(T.untyped) }
  def reload_blob; end

  sig { params(ids: T.untyped).returns(T.untyped) }
  def blob_ids=(ids); end
end

class ActiveStorage::Attachment::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
  include ActiveStorage::Attachment::CustomFinderMethods
  include ActiveStorage::Attachment::QueryMethodsReturningAssociationRelation
  Elem = type_member(fixed: ActiveStorage::Attachment)

  sig { params(records: T.any(ActiveStorage::Attachment, T::Array[ActiveStorage::Attachment])).returns(T.self_type) }
  def <<(*records); end

  sig { params(records: T.any(ActiveStorage::Attachment, T::Array[ActiveStorage::Attachment])).returns(T.self_type) }
  def append(*records); end

  sig { params(records: T.any(ActiveStorage::Attachment, T::Array[ActiveStorage::Attachment])).returns(T.self_type) }
  def push(*records); end

  sig { params(records: T.any(ActiveStorage::Attachment, T::Array[ActiveStorage::Attachment])).returns(T.self_type) }
  def concat(*records); end

  sig { params(num: T.nilable(Integer)).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def page(num = nil); end

  sig { params(num: Integer, max_per_page: T.nilable(Integer)).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def per(num, max_per_page = nil); end

  sig { params(num: Integer).returns(ActiveStorage::Attachment::ActiveRecord_AssociationRelation) }
  def padding(num); end
end
