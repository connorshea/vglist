# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `parlour` gem.
# Please instead update this file by running `tapioca sync`.

# typed: true

module Parlour
end

class Parlour::ConflictResolver
  sig { params(namespace: Parlour::RbiGenerator::Namespace, resolver: T.proc.params(desc: String, choices: T::Array[Parlour::RbiGenerator::RbiObject]).returns(Parlour::RbiGenerator::RbiObject)).void }
  def resolve_conflicts(namespace, &resolver); end

  private

  sig { params(arr: T::Array[T.untyped]).returns(T::Boolean) }
  def all_eql?(arr); end
  sig { params(arr: T::Array[T.untyped]).returns(T.nilable(Symbol)) }
  def merge_strategy(arr); end
end

module Parlour::Debugging
  class << self
    sig { params(value: T::Boolean).returns(T::Boolean) }
    def debug_mode=(value); end
    sig { returns(T::Boolean) }
    def debug_mode?; end
    sig { params(object: T.untyped, message: String).void }
    def debug_puts(object, message); end
    sig { params(object: T.untyped).returns(String) }
    def name_for_debug_caller(object); end
  end
end

module Parlour::Debugging::Tree
  class << self
    sig { params(message: String).returns(String) }
    def begin(message); end
    sig { params(message: String).returns(String) }
    def end(message); end
    sig { params(message: String).returns(String) }
    def here(message); end
    def line_prefix; end
    def text_prefix; end
  end
end

Parlour::Debugging::Tree::INDENT_SPACES = T.let(T.unsafe(nil), Integer)

class Parlour::DetachedRbiGenerator < ::Parlour::RbiGenerator
  sig { override.returns(T.nilable(Parlour::Plugin)) }
  def current_plugin; end
  sig { returns(T.untyped) }
  def detached!; end
  sig { override.returns(Parlour::RbiGenerator::Options) }
  def options; end
  sig { override.params(strictness: String).returns(String) }
  def rbi(strictness = T.unsafe(nil)); end
  sig { override.returns(Parlour::RbiGenerator::Namespace) }
  def root; end
end

class Parlour::ParseError < ::StandardError
  def initialize(buffer, range); end

  sig { returns(Parser::Source::Buffer) }
  def buffer; end
  sig { returns(Parser::Source::Range) }
  def range; end
end

class Parlour::Plugin
  abstract!

  sig { params(options: T::Hash[T.untyped, T.untyped]).void }
  def initialize(options); end

  sig { abstract.params(root: Parlour::RbiGenerator::Namespace).void }
  def generate(root); end
  sig { returns(T.nilable(String)) }
  def strictness; end
  def strictness=(_arg0); end

  class << self
    sig { params(new_plugin: T.class_of(Parlour::Plugin)).void }
    def inherited(new_plugin); end
    sig { returns(T::Hash[String, T.class_of(Parlour::Plugin)]) }
    def registered_plugins; end
    sig { params(plugins: T::Array[Parlour::Plugin], generator: Parlour::RbiGenerator, allow_failure: T::Boolean).void }
    def run_plugins(plugins, generator, allow_failure: T.unsafe(nil)); end
  end
end

class Parlour::RbiGenerator
  sig { params(break_params: Integer, tab_size: Integer, sort_namespaces: T::Boolean).void }
  def initialize(break_params: T.unsafe(nil), tab_size: T.unsafe(nil), sort_namespaces: T.unsafe(nil)); end

  sig { overridable.returns(T.nilable(Parlour::Plugin)) }
  def current_plugin; end
  def current_plugin=(_arg0); end
  sig { overridable.returns(Parlour::RbiGenerator::Options) }
  def options; end
  sig { overridable.params(strictness: String).returns(String) }
  def rbi(strictness = T.unsafe(nil)); end
  sig { overridable.returns(Parlour::RbiGenerator::Namespace) }
  def root; end
end

class Parlour::RbiGenerator::Arbitrary < ::Parlour::RbiGenerator::RbiObject
  sig { params(generator: Parlour::RbiGenerator, code: String, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Arbitrary).void)).void }
  def initialize(generator, code: T.unsafe(nil), &block); end

  sig { params(other: Object).returns(T::Boolean) }
  def ==(other); end
  sig { returns(String) }
  def code; end
  def code=(_arg0); end
  sig { override.returns(String) }
  def describe; end
  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
end

class Parlour::RbiGenerator::Attribute < ::Parlour::RbiGenerator::Method
  sig { params(generator: Parlour::RbiGenerator, name: String, kind: Symbol, type: String, class_attribute: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Attribute).void)).void }
  def initialize(generator, name, kind, type, class_attribute: T.unsafe(nil), &block); end

  sig { override.params(other: Object).returns(T::Boolean) }
  def ==(other); end
  sig { returns(T::Boolean) }
  def class_attribute; end
  sig { returns(Symbol) }
  def kind; end

  private

  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_definition(indent_level, options); end
end

class Parlour::RbiGenerator::ClassNamespace < ::Parlour::RbiGenerator::Namespace
  sig { params(generator: Parlour::RbiGenerator, name: String, final: T::Boolean, superclass: T.nilable(String), abstract: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::ClassNamespace).void)).void }
  def initialize(generator, name, final, superclass, abstract, &block); end

  sig { returns(T::Boolean) }
  def abstract; end
  sig { override.returns(String) }
  def describe; end
  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
  sig { returns(T.nilable(String)) }
  def superclass; end
end

class Parlour::RbiGenerator::Constant < ::Parlour::RbiGenerator::RbiObject
  sig { params(generator: Parlour::RbiGenerator, name: String, value: String, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Constant).void)).void }
  def initialize(generator, name: T.unsafe(nil), value: T.unsafe(nil), &block); end

  sig { params(other: Object).returns(T::Boolean) }
  def ==(other); end
  sig { override.returns(String) }
  def describe; end
  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
  sig { returns(String) }
  def value; end
end

class Parlour::RbiGenerator::EnumClassNamespace < ::Parlour::RbiGenerator::ClassNamespace
  sig { params(generator: Parlour::RbiGenerator, name: String, final: T::Boolean, enums: T::Array[T.any(String, [String, String])], abstract: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::EnumClassNamespace).void)).void }
  def initialize(generator, name, final, enums, abstract, &block); end

  sig { returns(T::Array[T.any(String, [String, String])]) }
  def enums; end
  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_body(indent_level, options); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
end

class Parlour::RbiGenerator::Extend < ::Parlour::RbiGenerator::RbiObject
  sig { params(generator: Parlour::RbiGenerator, name: String, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Extend).void)).void }
  def initialize(generator, name: T.unsafe(nil), &block); end

  sig { params(other: Object).returns(T::Boolean) }
  def ==(other); end
  sig { override.returns(String) }
  def describe; end
  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
end

class Parlour::RbiGenerator::Include < ::Parlour::RbiGenerator::RbiObject
  sig { params(generator: Parlour::RbiGenerator, name: String, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Include).void)).void }
  def initialize(generator, name: T.unsafe(nil), &block); end

  sig { params(other: Object).returns(T::Boolean) }
  def ==(other); end
  sig { override.returns(String) }
  def describe; end
  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
end

class Parlour::RbiGenerator::Method < ::Parlour::RbiGenerator::RbiObject
  sig { params(generator: Parlour::RbiGenerator, name: String, parameters: T::Array[Parlour::RbiGenerator::Parameter], return_type: T.nilable(String), abstract: T::Boolean, implementation: T::Boolean, override: T::Boolean, overridable: T::Boolean, class_method: T::Boolean, final: T::Boolean, type_parameters: T.nilable(T::Array[Symbol]), block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Method).void)).void }
  def initialize(generator, name, parameters, return_type = T.unsafe(nil), abstract: T.unsafe(nil), implementation: T.unsafe(nil), override: T.unsafe(nil), overridable: T.unsafe(nil), class_method: T.unsafe(nil), final: T.unsafe(nil), type_parameters: T.unsafe(nil), &block); end

  sig { overridable.params(other: Object).returns(T::Boolean) }
  def ==(other); end
  sig { returns(T::Boolean) }
  def abstract; end
  sig { returns(T::Boolean) }
  def class_method; end
  sig { override.returns(String) }
  def describe; end
  sig { returns(T::Boolean) }
  def final; end
  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { returns(T::Boolean) }
  def implementation; end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
  sig { returns(T::Boolean) }
  def overridable; end
  sig { returns(T::Boolean) }
  def override; end
  sig { returns(T::Array[Parlour::RbiGenerator::Parameter]) }
  def parameters; end
  sig { returns(T.nilable(String)) }
  def return_type; end
  sig { returns(T::Array[Symbol]) }
  def type_parameters; end

  private

  sig { overridable.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_definition(indent_level, options); end
  sig { returns(String) }
  def qualifiers; end
end

class Parlour::RbiGenerator::ModuleNamespace < ::Parlour::RbiGenerator::Namespace
  sig { params(generator: Parlour::RbiGenerator, name: String, final: T::Boolean, interface: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::ClassNamespace).void)).void }
  def initialize(generator, name, final, interface, &block); end

  sig { override.returns(String) }
  def describe; end
  sig { override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { returns(T::Boolean) }
  def interface; end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
end

class Parlour::RbiGenerator::Namespace < ::Parlour::RbiGenerator::RbiObject
  sig { params(generator: Parlour::RbiGenerator, name: T.nilable(String), final: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Namespace).void)).void }
  def initialize(generator, name = T.unsafe(nil), final = T.unsafe(nil), &block); end

  sig { params(comment: T.any(String, T::Array[String])).void }
  def add_comment_to_next_child(comment); end
  sig { returns(T::Array[Parlour::RbiGenerator::RbiObject]) }
  def children; end
  sig { returns(T::Array[Parlour::RbiGenerator::Constant]) }
  def constants; end
  def create_arbitrary(code:, &block); end
  def create_attr(*args, &blk); end
  sig { params(name: String, type: String, class_attribute: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Attribute).void)).returns(Parlour::RbiGenerator::Attribute) }
  def create_attr_accessor(name, type:, class_attribute: T.unsafe(nil), &block); end
  sig { params(name: String, type: String, class_attribute: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Attribute).void)).returns(Parlour::RbiGenerator::Attribute) }
  def create_attr_reader(name, type:, class_attribute: T.unsafe(nil), &block); end
  sig { params(name: String, type: String, class_attribute: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Attribute).void)).returns(Parlour::RbiGenerator::Attribute) }
  def create_attr_writer(name, type:, class_attribute: T.unsafe(nil), &block); end
  sig { params(name: String, kind: Symbol, type: String, class_attribute: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Attribute).void)).returns(Parlour::RbiGenerator::Attribute) }
  def create_attribute(name, kind:, type:, class_attribute: T.unsafe(nil), &block); end
  sig { params(name: String, final: T::Boolean, superclass: T.nilable(String), abstract: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::ClassNamespace).void)).returns(Parlour::RbiGenerator::ClassNamespace) }
  def create_class(name, final: T.unsafe(nil), superclass: T.unsafe(nil), abstract: T.unsafe(nil), &block); end
  sig { params(name: String, value: String, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Constant).void)).returns(Parlour::RbiGenerator::Constant) }
  def create_constant(name, value:, &block); end
  sig { params(name: String, final: T::Boolean, enums: T.nilable(T::Array[T.any(String, [String, String])]), abstract: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::EnumClassNamespace).void)).returns(Parlour::RbiGenerator::EnumClassNamespace) }
  def create_enum_class(name, final: T.unsafe(nil), enums: T.unsafe(nil), abstract: T.unsafe(nil), &block); end
  sig { params(name: String, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Extend).void)).returns(Parlour::RbiGenerator::Extend) }
  def create_extend(name, &block); end
  sig { params(extendables: T::Array[String]).returns(T::Array[Parlour::RbiGenerator::Extend]) }
  def create_extends(extendables); end
  sig { params(name: String, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Include).void)).returns(Parlour::RbiGenerator::Include) }
  def create_include(name, &block); end
  sig { params(includables: T::Array[String]).returns(T::Array[Parlour::RbiGenerator::Include]) }
  def create_includes(includables); end
  sig { params(name: String, parameters: T.nilable(T::Array[Parlour::RbiGenerator::Parameter]), return_type: T.nilable(String), returns: T.nilable(String), abstract: T::Boolean, implementation: T::Boolean, override: T::Boolean, overridable: T::Boolean, class_method: T::Boolean, final: T::Boolean, type_parameters: T.nilable(T::Array[Symbol]), block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Method).void)).returns(Parlour::RbiGenerator::Method) }
  def create_method(name, parameters: T.unsafe(nil), return_type: T.unsafe(nil), returns: T.unsafe(nil), abstract: T.unsafe(nil), implementation: T.unsafe(nil), override: T.unsafe(nil), overridable: T.unsafe(nil), class_method: T.unsafe(nil), final: T.unsafe(nil), type_parameters: T.unsafe(nil), &block); end
  sig { params(name: String, final: T::Boolean, interface: T::Boolean, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::ClassNamespace).void)).returns(Parlour::RbiGenerator::ModuleNamespace) }
  def create_module(name, final: T.unsafe(nil), interface: T.unsafe(nil), &block); end
  sig { params(name: String, type: String, block: T.nilable(T.proc.params(x: Parlour::RbiGenerator::Constant).void)).returns(Parlour::RbiGenerator::Constant) }
  def create_type_alias(name, type:, &block); end
  sig { overridable.override.returns(String) }
  def describe; end
  sig { returns(T::Array[Parlour::RbiGenerator::Extend]) }
  def extends; end
  sig { returns(T::Boolean) }
  def final; end
  sig { overridable.override.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { returns(T::Array[Parlour::RbiGenerator::Include]) }
  def includes; end
  sig { overridable.override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { overridable.override.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
  sig { params(object: T.untyped, block: T.proc.params(x: Parlour::RbiGenerator::Namespace).void).void }
  def path(object, &block); end

  private

  sig { overridable.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_body(indent_level, options); end
  sig { params(object: Parlour::RbiGenerator::RbiObject).void }
  def move_next_comments(object); end
end

class Parlour::RbiGenerator::Options
  sig { params(break_params: Integer, tab_size: Integer, sort_namespaces: T::Boolean).void }
  def initialize(break_params:, tab_size:, sort_namespaces:); end

  sig { returns(Integer) }
  def break_params; end
  sig { params(level: Integer, str: String).returns(String) }
  def indented(level, str); end
  sig { returns(T::Boolean) }
  def sort_namespaces; end
  sig { returns(Integer) }
  def tab_size; end
end

class Parlour::RbiGenerator::Parameter
  sig { params(name: String, type: T.nilable(String), default: T.nilable(String)).void }
  def initialize(name, type: T.unsafe(nil), default: T.unsafe(nil)); end

  sig { params(other: Object).returns(T::Boolean) }
  def ==(other); end
  sig { returns(T.nilable(String)) }
  def default; end
  sig { returns(Symbol) }
  def kind; end
  sig { returns(String) }
  def name; end
  sig { returns(String) }
  def name_without_kind; end
  sig { returns(String) }
  def to_def_param; end
  sig { returns(String) }
  def to_sig_param; end
  sig { returns(T.nilable(String)) }
  def type; end
end

Parlour::RbiGenerator::Parameter::PREFIXES = T.let(T.unsafe(nil), Hash)

class Parlour::RbiGenerator::RbiObject
  abstract!

  sig { params(generator: Parlour::RbiGenerator, name: String).void }
  def initialize(generator, name); end

  sig { params(comment: T.any(String, T::Array[String])).void }
  def add_comment(comment); end
  def add_comments(*args, &blk); end
  sig { returns(T::Array[String]) }
  def comments; end
  sig { abstract.returns(String) }
  def describe; end
  sig { abstract.params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_rbi(indent_level, options); end
  sig { returns(T.nilable(Parlour::Plugin)) }
  def generated_by; end
  sig { returns(Parlour::RbiGenerator) }
  def generator; end
  sig { abstract.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).void }
  def merge_into_self(others); end
  sig { abstract.params(others: T::Array[Parlour::RbiGenerator::RbiObject]).returns(T::Boolean) }
  def mergeable?(others); end
  sig { returns(String) }
  def name; end

  private

  sig { params(indent_level: Integer, options: Parlour::RbiGenerator::Options).returns(T::Array[String]) }
  def generate_comments(indent_level, options); end
end

module Parlour::TypeLoader
  class << self
    sig { params(filename: String).returns(Parlour::RbiGenerator::Namespace) }
    def load_file(filename); end
    sig { params(root: String, exclusions: T::Array[String]).returns(Parlour::RbiGenerator::Namespace) }
    def load_project(root, exclusions: T.unsafe(nil)); end
    sig { params(source: String, filename: T.nilable(String)).returns(Parlour::RbiGenerator::Namespace) }
    def load_source(source, filename = T.unsafe(nil)); end
  end
end

class Parlour::TypeParser
  sig { params(ast: Parser::AST::Node, unknown_node_errors: T::Boolean).void }
  def initialize(ast, unknown_node_errors: T.unsafe(nil)); end

  sig { returns(Parser::AST::Node) }
  def ast; end
  def ast=(_arg0); end
  sig { returns(Parlour::RbiGenerator::Namespace) }
  def parse_all; end
  sig { params(path: Parlour::TypeParser::NodePath, is_within_eigenclass: T::Boolean).returns(T::Array[Parlour::RbiGenerator::RbiObject]) }
  def parse_path_to_object(path, is_within_eigenclass: T.unsafe(nil)); end
  sig { params(path: Parlour::TypeParser::NodePath, is_within_eigenclass: T::Boolean).returns(T::Array[Parlour::RbiGenerator::Method]) }
  def parse_sig_into_methods(path, is_within_eigenclass: T.unsafe(nil)); end
  sig { params(path: Parlour::TypeParser::NodePath).returns(Parlour::TypeParser::IntermediateSig) }
  def parse_sig_into_sig(path); end
  sig { returns(T::Boolean) }
  def unknown_node_errors; end

  protected

  sig { params(node: T.nilable(Parser::AST::Node), modifier: Symbol).returns(T::Boolean) }
  def body_has_modifier?(node, modifier); end
  sig { params(node: Parser::AST::Node).returns([T::Array[String], T::Array[String]]) }
  def body_includes_and_extends(node); end
  sig { params(node: T.nilable(Parser::AST::Node)).returns(T::Array[Symbol]) }
  def constant_names(node); end
  sig { params(node: T.nilable(Parser::AST::Node)).returns(T.nilable(String)) }
  def node_to_s(node); end
  sig { params(desc: String, node: T.any(Parlour::TypeParser::NodePath, Parser::AST::Node)).returns(T.noreturn) }
  def parse_err(desc, node); end
  sig { params(node: Parser::AST::Node).returns(T::Boolean) }
  def sig_node?(node); end
  sig { type_parameters(:A, :B).params(a: T::Array[T.type_parameter(:A)], fa: T.proc.params(item: T.type_parameter(:A)).returns(T.untyped), b: T::Array[T.type_parameter(:B)], fb: T.proc.params(item: T.type_parameter(:B)).returns(T.untyped)).returns(T::Array[[T.type_parameter(:A), T.type_parameter(:B)]]) }
  def zip_by(a, fa, b, fb); end

  class << self
    sig { params(filename: String, source: String).returns(Parlour::TypeParser) }
    def from_source(filename, source); end
  end
end

class Parlour::TypeParser::IntermediateSig < ::T::Struct
  prop :type_parameters, T.nilable(T::Array[Symbol])
  prop :overridable, T::Boolean
  prop :override, T::Boolean
  prop :abstract, T::Boolean
  prop :final, T::Boolean
  prop :return_type, T.nilable(String)
  prop :params, T.nilable(T::Array[Parser::AST::Node])

  class << self
    def inherited(s); end
  end
end

class Parlour::TypeParser::NodePath
  sig { params(indices: T::Array[Integer]).void }
  def initialize(indices); end

  sig { params(index: Integer).returns(Parlour::TypeParser::NodePath) }
  def child(index); end
  sig { returns(T::Array[Integer]) }
  def indices; end
  sig { returns(Parlour::TypeParser::NodePath) }
  def parent; end
  sig { params(offset: Integer).returns(Parlour::TypeParser::NodePath) }
  def sibling(offset); end
  sig { params(start: Parser::AST::Node).returns(Parser::AST::Node) }
  def traverse(start); end
end

Parlour::VERSION = T.let(T.unsafe(nil), String)
