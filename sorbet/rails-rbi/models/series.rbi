# This is an autogenerated file for dynamic methods in Series
# Please rerun rake rails_rbi:models[Series] to regenerate.

# typed: strong
module Series::ActiveRelation_WhereNot
  sig { params(opts: T.untyped, rest: T.untyped).returns(T.self_type) }
  def not(opts, *rest); end
end

module Series::GeneratedAttributeMethods
  extend T::Sig

  sig { returns(DateTime) }
  def created_at; end

  sig { params(value: DateTime).void }
  def created_at=(value); end

  sig { returns(T::Boolean) }
  def created_at?; end

  sig { returns(Integer) }
  def id; end

  sig { params(value: Integer).void }
  def id=(value); end

  sig { returns(T::Boolean) }
  def id?; end

  sig { returns(String) }
  def name; end

  sig { params(value: String).void }
  def name=(value); end

  sig { returns(T::Boolean) }
  def name?; end

  sig { returns(DateTime) }
  def updated_at; end

  sig { params(value: DateTime).void }
  def updated_at=(value); end

  sig { returns(T::Boolean) }
  def updated_at?; end

  sig { returns(T.nilable(Integer)) }
  def wikidata_id; end

  sig { params(value: T.nilable(Integer)).void }
  def wikidata_id=(value); end

  sig { returns(T::Boolean) }
  def wikidata_id?; end
end

module Series::GeneratedAssociationMethods
  extend T::Sig

  sig { returns(::Game::ActiveRecord_Associations_CollectionProxy) }
  def games; end

  sig { params(value: T.any(T::Array[::Game], ::Game::ActiveRecord_Associations_CollectionProxy)).void }
  def games=(value); end

  sig { returns(T.nilable(::PgSearch::Document)) }
  def pg_search_document; end

  sig { params(value: T.nilable(::PgSearch::Document)).void }
  def pg_search_document=(value); end
end

module Series::CustomFinderMethods
  sig { params(limit: Integer).returns(T::Array[Series]) }
  def first_n(limit); end

  sig { params(limit: Integer).returns(T::Array[Series]) }
  def last_n(limit); end

  sig { params(args: T::Array[T.any(Integer, String)]).returns(T::Array[Series]) }
  def find_n(*args); end

  sig { params(id: Integer).returns(T.nilable(Series)) }
  def find_by_id(id); end

  sig { params(id: Integer).returns(Series) }
  def find_by_id!(id); end
end

module Series::ModelRelationShared
  extend T::Sig

  sig { returns(Series::ActiveRecord_Relation) }
  def all; end

  sig { params(block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def unscoped(&block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def select(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def order(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def reorder(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def group(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def limit(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def offset(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def joins(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def left_joins(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def left_outer_joins(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def where(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def rewhere(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def preload(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def eager_load(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def includes(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def from(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def lock(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def readonly(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def extending(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def or(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def having(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def create_with(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def distinct(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def references(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def none(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def unscope(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def merge(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(Series::ActiveRecord_Relation) }
  def except(*args, &block); end

  sig { params(num: Integer).returns(Series::ActiveRecord_Relation) }
  def page(num = nil); end
end

class Series::ActiveRecord_Relation < ActiveRecord::Relation
  include Series::ActiveRelation_WhereNot
  include SorbetRails::CustomFinderMethods
  include Series::CustomFinderMethods
  include Enumerable
  include Series::ModelRelationShared
  extend T::Sig
  extend T::Generic
  Elem = type_member(fixed: Series)

  sig { params(args: T.untyped).returns(Series) }
  def find(*args); end

  sig { params(args: T.untyped).returns(T.nilable(Series)) }
  def find_by(*args); end

  sig { params(args: T.untyped).returns(Series) }
  def find_by!(*args); end

  sig { returns(T.nilable(Series)) }
  def first; end

  sig { returns(Series) }
  def first!; end

  sig { returns(T.nilable(Series)) }
  def second; end

  sig { returns(Series) }
  def second!; end

  sig { returns(T.nilable(Series)) }
  def third; end

  sig { returns(Series) }
  def third!; end

  sig { returns(T.nilable(Series)) }
  def third_to_last; end

  sig { returns(Series) }
  def third_to_last!; end

  sig { returns(T.nilable(Series)) }
  def second_to_last; end

  sig { returns(Series) }
  def second_to_last!; end

  sig { returns(T.nilable(Series)) }
  def last; end

  sig { returns(Series) }
  def last!; end

  sig { params(conditions: T.untyped).returns(T::Boolean) }
  def exists?(conditions = nil); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def any?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def many?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def none?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def one?(*args); end

  sig { implementation.params(block: T.proc.params(e: Series).void).void }
  def each(&block); end

  sig { params(level: T.nilable(Integer)).returns(T::Array[Series]) }
  def flatten(level); end

  sig { returns(T::Array[Series]) }
  def to_a; end
end

class Series::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
  include Series::ActiveRelation_WhereNot
  include SorbetRails::CustomFinderMethods
  include Series::CustomFinderMethods
  include Enumerable
  include Series::ModelRelationShared
  extend T::Sig
  extend T::Generic
  Elem = type_member(fixed: Series)

  sig { params(args: T.untyped).returns(Series) }
  def find(*args); end

  sig { params(args: T.untyped).returns(T.nilable(Series)) }
  def find_by(*args); end

  sig { params(args: T.untyped).returns(Series) }
  def find_by!(*args); end

  sig { returns(T.nilable(Series)) }
  def first; end

  sig { returns(Series) }
  def first!; end

  sig { returns(T.nilable(Series)) }
  def second; end

  sig { returns(Series) }
  def second!; end

  sig { returns(T.nilable(Series)) }
  def third; end

  sig { returns(Series) }
  def third!; end

  sig { returns(T.nilable(Series)) }
  def third_to_last; end

  sig { returns(Series) }
  def third_to_last!; end

  sig { returns(T.nilable(Series)) }
  def second_to_last; end

  sig { returns(Series) }
  def second_to_last!; end

  sig { returns(T.nilable(Series)) }
  def last; end

  sig { returns(Series) }
  def last!; end

  sig { params(conditions: T.untyped).returns(T::Boolean) }
  def exists?(conditions = nil); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def any?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def many?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def none?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def one?(*args); end

  sig { implementation.params(block: T.proc.params(e: Series).void).void }
  def each(&block); end

  sig { params(level: T.nilable(Integer)).returns(T::Array[Series]) }
  def flatten(level); end

  sig { returns(T::Array[Series]) }
  def to_a; end

  sig { params(records: T.any(Series, T::Array[Series])).returns(T.self_type) }
  def <<(*records); end

  sig { params(records: T.any(Series, T::Array[Series])).returns(T.self_type) }
  def append(*records); end

  sig { params(records: T.any(Series, T::Array[Series])).returns(T.self_type) }
  def push(*records); end

  sig { params(records: T.any(Series, T::Array[Series])).returns(T.self_type) }
  def concat(*records); end
end

class Series < ApplicationRecord
  include Series::GeneratedAttributeMethods
  include Series::GeneratedAssociationMethods
  extend SorbetRails::CustomFinderMethods
  extend Series::CustomFinderMethods
  extend PgSearch::Model::ClassMethods
  extend T::Sig
  extend T::Generic
  extend Series::ModelRelationShared

  sig { params(args: T.untyped).returns(Series) }
  def self.find(*args); end

  sig { params(args: T.untyped).returns(T.nilable(Series)) }
  def self.find_by(*args); end

  sig { params(args: T.untyped).returns(Series) }
  def self.find_by!(*args); end

  sig { returns(T.nilable(Series)) }
  def self.first; end

  sig { returns(Series) }
  def self.first!; end

  sig { returns(T.nilable(Series)) }
  def self.second; end

  sig { returns(Series) }
  def self.second!; end

  sig { returns(T.nilable(Series)) }
  def self.third; end

  sig { returns(Series) }
  def self.third!; end

  sig { returns(T.nilable(Series)) }
  def self.third_to_last; end

  sig { returns(Series) }
  def self.third_to_last!; end

  sig { returns(T.nilable(Series)) }
  def self.second_to_last; end

  sig { returns(Series) }
  def self.second_to_last!; end

  sig { returns(T.nilable(Series)) }
  def self.last; end

  sig { returns(Series) }
  def self.last!; end

  sig { params(conditions: T.untyped).returns(T::Boolean) }
  def self.exists?(conditions = nil); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def self.any?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def self.many?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def self.none?(*args); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def self.one?(*args); end
end
