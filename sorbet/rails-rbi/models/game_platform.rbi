# This is an autogenerated file for dynamic methods in GamePlatform
# Please rerun rake rails_rbi:models[GamePlatform] to regenerate.

# typed: strong
module GamePlatform::ActiveRelation_WhereNot
  sig { params(opts: T.untyped, rest: T.untyped).returns(T.self_type) }
  def not(opts, *rest); end
end

module GamePlatform::GeneratedAttributeMethods
  extend T::Sig

  sig { returns(DateTime) }
  def created_at; end

  sig { params(value: DateTime).void }
  def created_at=(value); end

  sig { returns(T::Boolean) }
  def created_at?; end

  sig { returns(Integer) }
  def game_id; end

  sig { params(value: Integer).void }
  def game_id=(value); end

  sig { returns(T::Boolean) }
  def game_id?; end

  sig { returns(Integer) }
  def id; end

  sig { params(value: Integer).void }
  def id=(value); end

  sig { returns(T::Boolean) }
  def id?; end

  sig { returns(Integer) }
  def platform_id; end

  sig { params(value: Integer).void }
  def platform_id=(value); end

  sig { returns(T::Boolean) }
  def platform_id?; end

  sig { returns(DateTime) }
  def updated_at; end

  sig { params(value: DateTime).void }
  def updated_at=(value); end

  sig { returns(T::Boolean) }
  def updated_at?; end
end

module GamePlatform::GeneratedAssociationMethods
  extend T::Sig

  sig { returns(::Game) }
  def game; end

  sig { params(value: ::Game).void }
  def game=(value); end

  sig { returns(::Platform) }
  def platform; end

  sig { params(value: ::Platform).void }
  def platform=(value); end
end

module GamePlatform::CustomFinderMethods
  sig { params(limit: Integer).returns(T::Array[GamePlatform]) }
  def first_n(limit); end

  sig { params(limit: Integer).returns(T::Array[GamePlatform]) }
  def last_n(limit); end

  sig { params(args: T::Array[T.any(Integer, String)]).returns(T::Array[GamePlatform]) }
  def find_n(*args); end

  sig { params(id: Integer).returns(T.nilable(GamePlatform)) }
  def find_by_id(id); end

  sig { params(id: Integer).returns(GamePlatform) }
  def find_by_id!(id); end
end

module GamePlatform::ModelRelationShared
  extend T::Sig

  sig { returns(GamePlatform::ActiveRecord_Relation) }
  def all; end

  sig { params(block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def unscoped(&block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def select(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def order(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def reorder(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def group(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def limit(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def offset(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def joins(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def left_joins(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def left_outer_joins(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def where(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def rewhere(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def preload(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def eager_load(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def includes(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def from(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def lock(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def readonly(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def extending(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def or(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def having(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def create_with(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def distinct(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def references(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def none(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def unscope(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def merge(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(GamePlatform::ActiveRecord_Relation) }
  def except(*args, &block); end

  sig { params(num: Integer).returns(GamePlatform::ActiveRecord_Relation) }
  def page(num = nil); end
end

class GamePlatform::ActiveRecord_Relation < ActiveRecord::Relation
  include GamePlatform::ActiveRelation_WhereNot
  include SorbetRails::CustomFinderMethods
  include GamePlatform::CustomFinderMethods
  include Enumerable
  include GamePlatform::ModelRelationShared
  extend T::Sig
  extend T::Generic
  Elem = type_member(fixed: GamePlatform)

  sig { params(args: T.untyped).returns(GamePlatform) }
  def find(*args); end

  sig { params(args: T.untyped).returns(T.nilable(GamePlatform)) }
  def find_by(*args); end

  sig { params(args: T.untyped).returns(GamePlatform) }
  def find_by!(*args); end

  sig { returns(T.nilable(GamePlatform)) }
  def first; end

  sig { returns(GamePlatform) }
  def first!; end

  sig { returns(T.nilable(GamePlatform)) }
  def second; end

  sig { returns(GamePlatform) }
  def second!; end

  sig { returns(T.nilable(GamePlatform)) }
  def third; end

  sig { returns(GamePlatform) }
  def third!; end

  sig { returns(T.nilable(GamePlatform)) }
  def third_to_last; end

  sig { returns(GamePlatform) }
  def third_to_last!; end

  sig { returns(T.nilable(GamePlatform)) }
  def second_to_last; end

  sig { returns(GamePlatform) }
  def second_to_last!; end

  sig { returns(T.nilable(GamePlatform)) }
  def last; end

  sig { returns(GamePlatform) }
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

  sig { implementation.params(block: T.proc.params(e: GamePlatform).void).void }
  def each(&block); end

  sig { params(level: T.nilable(Integer)).returns(T::Array[GamePlatform]) }
  def flatten(level); end

  sig { returns(T::Array[GamePlatform]) }
  def to_a; end
end

class GamePlatform::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
  include GamePlatform::ActiveRelation_WhereNot
  include SorbetRails::CustomFinderMethods
  include GamePlatform::CustomFinderMethods
  include Enumerable
  include GamePlatform::ModelRelationShared
  extend T::Sig
  extend T::Generic
  Elem = type_member(fixed: GamePlatform)

  sig { params(args: T.untyped).returns(GamePlatform) }
  def find(*args); end

  sig { params(args: T.untyped).returns(T.nilable(GamePlatform)) }
  def find_by(*args); end

  sig { params(args: T.untyped).returns(GamePlatform) }
  def find_by!(*args); end

  sig { returns(T.nilable(GamePlatform)) }
  def first; end

  sig { returns(GamePlatform) }
  def first!; end

  sig { returns(T.nilable(GamePlatform)) }
  def second; end

  sig { returns(GamePlatform) }
  def second!; end

  sig { returns(T.nilable(GamePlatform)) }
  def third; end

  sig { returns(GamePlatform) }
  def third!; end

  sig { returns(T.nilable(GamePlatform)) }
  def third_to_last; end

  sig { returns(GamePlatform) }
  def third_to_last!; end

  sig { returns(T.nilable(GamePlatform)) }
  def second_to_last; end

  sig { returns(GamePlatform) }
  def second_to_last!; end

  sig { returns(T.nilable(GamePlatform)) }
  def last; end

  sig { returns(GamePlatform) }
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

  sig { implementation.params(block: T.proc.params(e: GamePlatform).void).void }
  def each(&block); end

  sig { params(level: T.nilable(Integer)).returns(T::Array[GamePlatform]) }
  def flatten(level); end

  sig { returns(T::Array[GamePlatform]) }
  def to_a; end

  sig { params(records: T.any(GamePlatform, T::Array[GamePlatform])).returns(T.self_type) }
  def <<(*records); end

  sig { params(records: T.any(GamePlatform, T::Array[GamePlatform])).returns(T.self_type) }
  def append(*records); end

  sig { params(records: T.any(GamePlatform, T::Array[GamePlatform])).returns(T.self_type) }
  def push(*records); end

  sig { params(records: T.any(GamePlatform, T::Array[GamePlatform])).returns(T.self_type) }
  def concat(*records); end
end

class GamePlatform < ApplicationRecord
  include GamePlatform::GeneratedAttributeMethods
  include GamePlatform::GeneratedAssociationMethods
  extend SorbetRails::CustomFinderMethods
  extend GamePlatform::CustomFinderMethods
  extend T::Sig
  extend T::Generic
  extend GamePlatform::ModelRelationShared

  sig { params(args: T.untyped).returns(GamePlatform) }
  def self.find(*args); end

  sig { params(args: T.untyped).returns(T.nilable(GamePlatform)) }
  def self.find_by(*args); end

  sig { params(args: T.untyped).returns(GamePlatform) }
  def self.find_by!(*args); end

  sig { returns(T.nilable(GamePlatform)) }
  def self.first; end

  sig { returns(GamePlatform) }
  def self.first!; end

  sig { returns(T.nilable(GamePlatform)) }
  def self.second; end

  sig { returns(GamePlatform) }
  def self.second!; end

  sig { returns(T.nilable(GamePlatform)) }
  def self.third; end

  sig { returns(GamePlatform) }
  def self.third!; end

  sig { returns(T.nilable(GamePlatform)) }
  def self.third_to_last; end

  sig { returns(GamePlatform) }
  def self.third_to_last!; end

  sig { returns(T.nilable(GamePlatform)) }
  def self.second_to_last; end

  sig { returns(GamePlatform) }
  def self.second_to_last!; end

  sig { returns(T.nilable(GamePlatform)) }
  def self.last; end

  sig { returns(GamePlatform) }
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
