# This is an autogenerated file for dynamic methods in GameDeveloper
# Please rerun bundle exec rake rails_rbi:models[GameDeveloper] to regenerate.

# typed: strong
module GameDeveloper::ActiveRelation_WhereNot
  sig { params(opts: T.untyped, rest: T.untyped).returns(T.self_type) }
  def not(opts, *rest); end
end

module GameDeveloper::CustomFinderMethods
  sig { params(limit: Integer).returns(T::Array[GameDeveloper]) }
  def first_n(limit); end

  sig { params(limit: Integer).returns(T::Array[GameDeveloper]) }
  def last_n(limit); end

  sig { params(args: T::Array[T.any(Integer, String)]).returns(T::Array[GameDeveloper]) }
  def find_n(*args); end

  sig { params(id: T.nilable(Integer)).returns(T.nilable(GameDeveloper)) }
  def find_by_id(id); end

  sig { params(id: Integer).returns(GameDeveloper) }
  def find_by_id!(id); end
end

class GameDeveloper < ApplicationRecord
  include GameDeveloper::GeneratedAttributeMethods
  include GameDeveloper::GeneratedAssociationMethods
  extend GameDeveloper::CustomFinderMethods
  extend GameDeveloper::QueryMethodsReturningRelation
  RelationType = T.type_alias { T.any(GameDeveloper::ActiveRecord_Relation, GameDeveloper::ActiveRecord_Associations_CollectionProxy, GameDeveloper::ActiveRecord_AssociationRelation) }

  sig { params(args: T.untyped).returns(T.untyped) }
  def autosave_associated_records_for_game(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def validate_associated_records_for_game(*args); end

  sig { returns(T.untyped) }
  def self.after_add_for_company; end

  sig { returns(T::Boolean) }
  def self.after_add_for_company?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def self.after_add_for_company=(val); end

  sig { returns(T.untyped) }
  def self.after_remove_for_company; end

  sig { returns(T::Boolean) }
  def self.after_remove_for_company?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def self.after_remove_for_company=(val); end

  sig { returns(T.untyped) }
  def self.before_add_for_company; end

  sig { returns(T::Boolean) }
  def self.before_add_for_company?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def self.before_add_for_company=(val); end

  sig { returns(T.untyped) }
  def self.before_remove_for_company; end

  sig { returns(T::Boolean) }
  def self.before_remove_for_company?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def self.before_remove_for_company=(val); end

  sig { returns(T.untyped) }
  def after_add_for_company; end

  sig { returns(T::Boolean) }
  def after_add_for_company?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def after_add_for_company=(val); end

  sig { returns(T.untyped) }
  def after_remove_for_company; end

  sig { returns(T::Boolean) }
  def after_remove_for_company?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def after_remove_for_company=(val); end

  sig { returns(T.untyped) }
  def before_add_for_company; end

  sig { returns(T::Boolean) }
  def before_add_for_company?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def before_add_for_company=(val); end

  sig { returns(T.untyped) }
  def before_remove_for_company; end

  sig { returns(T::Boolean) }
  def before_remove_for_company?; end

  sig { params(val: T.untyped).returns(T.untyped) }
  def before_remove_for_company=(val); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def autosave_associated_records_for_company(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def validate_associated_records_for_company(*args); end

  sig { params(num: T.nilable(Integer)).returns(GameDeveloper::ActiveRecord_Relation) }
  def self.page(num = nil); end

  sig { params(num: Integer, max_per_page: T.nilable(Integer)).returns(GameDeveloper::ActiveRecord_Relation) }
  def self.per(num, max_per_page = nil); end

  sig { params(num: Integer).returns(GameDeveloper::ActiveRecord_Relation) }
  def self.padding(num); end

  sig { returns(Integer) }
  def self.default_per_page; end
end

module GameDeveloper::QueryMethodsReturningRelation
  sig { returns(GameDeveloper::ActiveRecord_Relation) }
  def all; end

  sig { params(block: T.nilable(T.proc.void)).returns(GameDeveloper::ActiveRecord_Relation) }
  def unscoped(&block); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def reselect(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def order(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def reorder(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def group(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def limit(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def offset(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def joins(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def left_joins(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def left_outer_joins(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def where(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def rewhere(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def preload(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def extract_associated(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def eager_load(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def includes(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def from(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def lock(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def readonly(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def or(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def having(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def create_with(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def distinct(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def references(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def none(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def unscope(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def optimizer_hints(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def merge(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def except(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_Relation) }
  def only(*args); end

  sig { params(block: T.proc.params(e: GameDeveloper).returns(T::Boolean)).returns(T::Array[GameDeveloper]) }
  def select(&block); end

  sig { params(args: T.any(String, Symbol, T::Array[T.any(String, Symbol)])).returns(GameDeveloper::ActiveRecord_Relation) }
  def select_columns(*args); end

  sig { params(args: Symbol).returns(GameDeveloper::ActiveRecord_Relation) }
  def where_missing(*args); end

  sig { params(column: Symbol, values: T::Array[T.untyped]).returns(GameDeveloper::ActiveRecord_Relation) }
  def in_order_of(column, values); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GameDeveloper::ActiveRecord_Relation) }
  def extending(*args, &block); end

  sig do
    params(
      of: T.nilable(Integer),
      start: T.nilable(Integer),
      finish: T.nilable(Integer),
      load: T.nilable(T::Boolean),
      error_on_ignore: T.nilable(T::Boolean),
      block: T.nilable(T.proc.params(e: GameDeveloper::ActiveRecord_Relation).void)
    ).returns(ActiveRecord::Batches::BatchEnumerator)
  end
  def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, &block); end
end

module GameDeveloper::QueryMethodsReturningAssociationRelation
  sig { returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def all; end

  sig { params(block: T.nilable(T.proc.void)).returns(GameDeveloper::ActiveRecord_Relation) }
  def unscoped(&block); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def reselect(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def order(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def reorder(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def group(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def limit(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def offset(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def joins(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def left_joins(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def left_outer_joins(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def where(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def rewhere(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def preload(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def extract_associated(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def eager_load(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def includes(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def from(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def lock(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def readonly(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def or(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def having(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def create_with(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def distinct(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def references(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def none(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def unscope(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def optimizer_hints(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def merge(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def except(*args); end

  sig { params(args: T.untyped).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def only(*args); end

  sig { params(block: T.proc.params(e: GameDeveloper).returns(T::Boolean)).returns(T::Array[GameDeveloper]) }
  def select(&block); end

  sig { params(args: T.any(String, Symbol, T::Array[T.any(String, Symbol)])).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def select_columns(*args); end

  sig { params(args: Symbol).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def where_missing(*args); end

  sig { params(column: Symbol, values: T::Array[T.untyped]).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def in_order_of(column, values); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def extending(*args, &block); end

  sig do
    params(
      of: T.nilable(Integer),
      start: T.nilable(Integer),
      finish: T.nilable(Integer),
      load: T.nilable(T::Boolean),
      error_on_ignore: T.nilable(T::Boolean),
      block: T.nilable(T.proc.params(e: GameDeveloper::ActiveRecord_AssociationRelation).void)
    ).returns(ActiveRecord::Batches::BatchEnumerator)
  end
  def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, &block); end
end

class GameDeveloper::ActiveRecord_Relation < ActiveRecord::Relation
  include GameDeveloper::ActiveRelation_WhereNot
  include GameDeveloper::CustomFinderMethods
  include GameDeveloper::QueryMethodsReturningRelation
  Elem = type_member {{fixed: GameDeveloper}}

  sig { params(num: T.nilable(Integer)).returns(GameDeveloper::ActiveRecord_Relation) }
  def page(num = nil); end

  sig { params(num: Integer, max_per_page: T.nilable(Integer)).returns(GameDeveloper::ActiveRecord_Relation) }
  def per(num, max_per_page = nil); end

  sig { params(num: Integer).returns(GameDeveloper::ActiveRecord_Relation) }
  def padding(num); end

  sig { returns(T::Boolean) }
  def last_page?; end
end

class GameDeveloper::ActiveRecord_AssociationRelation < ActiveRecord::AssociationRelation
  include GameDeveloper::ActiveRelation_WhereNot
  include GameDeveloper::CustomFinderMethods
  include GameDeveloper::QueryMethodsReturningAssociationRelation
  Elem = type_member {{fixed: GameDeveloper}}

  sig { params(num: T.nilable(Integer)).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def page(num = nil); end

  sig { params(num: Integer, max_per_page: T.nilable(Integer)).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def per(num, max_per_page = nil); end

  sig { params(num: Integer).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def padding(num); end

  sig { returns(T::Boolean) }
  def last_page?; end
end

module GameDeveloper::GeneratedAttributeMethods
  sig { returns(Integer) }
  def company_id; end

  sig { params(value: T.any(Numeric, ActiveSupport::Duration)).void }
  def company_id=(value); end

  sig { returns(T::Boolean) }
  def company_id?; end

  sig { returns(ActiveSupport::TimeWithZone) }
  def created_at; end

  sig { params(value: T.any(Date, Time, ActiveSupport::TimeWithZone)).void }
  def created_at=(value); end

  sig { returns(T::Boolean) }
  def created_at?; end

  sig { returns(Integer) }
  def game_id; end

  sig { params(value: T.any(Numeric, ActiveSupport::Duration)).void }
  def game_id=(value); end

  sig { returns(T::Boolean) }
  def game_id?; end

  sig { returns(Integer) }
  def id; end

  sig { params(value: T.any(Numeric, ActiveSupport::Duration)).void }
  def id=(value); end

  sig { returns(T::Boolean) }
  def id?; end

  sig { returns(ActiveSupport::TimeWithZone) }
  def updated_at; end

  sig { params(value: T.any(Date, Time, ActiveSupport::TimeWithZone)).void }
  def updated_at=(value); end

  sig { returns(T::Boolean) }
  def updated_at?; end

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
  def saved_change_to_game_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_game_id(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def game_id_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_game_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def game_id_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def game_id_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def game_id_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def game_id_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def game_id_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def game_id_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def game_id_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def game_id_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_game_id!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def game_id_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def game_id_came_from_user?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def saved_change_to_company_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_company_id(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def company_id_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_company_id?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def company_id_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def company_id_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def company_id_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def company_id_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def company_id_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def company_id_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def company_id_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def company_id_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_company_id!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def company_id_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def company_id_came_from_user?(*args); end

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

  sig { params(args: T.untyped).returns(T::Boolean) }
  def saved_change_to_updated_at?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def saved_change_to_updated_at(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def updated_at_before_last_save(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def will_save_change_to_updated_at?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def updated_at_change_to_be_saved(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def updated_at_in_database(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def updated_at_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def updated_at_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def updated_at_will_change!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def updated_at_was(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def updated_at_previously_changed?(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def updated_at_previous_change(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def restore_updated_at!(*args); end

  sig { params(args: T.untyped).returns(T.untyped) }
  def updated_at_before_type_cast(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def updated_at_came_from_user?(*args); end
end

module GameDeveloper::GeneratedAssociationMethods
  sig { returns(::Company) }
  def company; end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::Company).void)).returns(::Company) }
  def build_company(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::Company).void)).returns(::Company) }
  def create_company(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::Company).void)).returns(::Company) }
  def create_company!(*args, &block); end

  sig { params(value: ::Company).void }
  def company=(value); end

  sig { returns(::Company) }
  def reload_company; end

  sig { returns(::Game) }
  def game; end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::Game).void)).returns(::Game) }
  def build_game(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::Game).void)).returns(::Game) }
  def create_game(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::Game).void)).returns(::Game) }
  def create_game!(*args, &block); end

  sig { params(value: ::Game).void }
  def game=(value); end

  sig { returns(::Game) }
  def reload_game; end

  sig { params(ids: T.untyped).returns(T.untyped) }
  def company_ids=(ids); end
end

class GameDeveloper::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
  include GameDeveloper::CustomFinderMethods
  include GameDeveloper::QueryMethodsReturningAssociationRelation
  Elem = type_member {{fixed: GameDeveloper}}

  sig { params(records: T.any(GameDeveloper, T::Array[GameDeveloper])).returns(T.self_type) }
  def <<(*records); end

  sig { params(records: T.any(GameDeveloper, T::Array[GameDeveloper])).returns(T.self_type) }
  def append(*records); end

  sig { params(records: T.any(GameDeveloper, T::Array[GameDeveloper])).returns(T.self_type) }
  def push(*records); end

  sig { params(records: T.any(GameDeveloper, T::Array[GameDeveloper])).returns(T.self_type) }
  def concat(*records); end

  sig { params(num: T.nilable(Integer)).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def page(num = nil); end

  sig { params(num: Integer, max_per_page: T.nilable(Integer)).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def per(num, max_per_page = nil); end

  sig { params(num: Integer).returns(GameDeveloper::ActiveRecord_AssociationRelation) }
  def padding(num); end

  sig { returns(T::Boolean) }
  def last_page?; end
end
