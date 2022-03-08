# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `ebnf` gem.
# Please instead update this file by running `bin/tapioca gem ebnf`.

module ABNFCore; end
ABNFCore::RULES = T.let(T.unsafe(nil), Array)
module ABNFMeta; end
ABNFMeta::RULES = T.let(T.unsafe(nil), Array)

module EBNF
  class << self
    def parse(input, **options); end
  end
end

class EBNF::ABNF
  include ::EBNF::PEG::Parser
  extend ::EBNF::PEG::Parser::ClassMethods

  def initialize(input, **options); end

  def ast; end
  def parsed_rules; end

  private

  def hex_or_string(characters); end
end

EBNF::ABNF::ALPHA = T.let(T.unsafe(nil), Regexp)
EBNF::ABNF::COMMENT = T.let(T.unsafe(nil), Regexp)
EBNF::ABNF::CRLF = T.let(T.unsafe(nil), Regexp)
EBNF::ABNF::C_NL = T.let(T.unsafe(nil), Regexp)
EBNF::ABNF::C_WSP = T.let(T.unsafe(nil), Regexp)
EBNF::ABNF::VCHAR = T.let(T.unsafe(nil), Regexp)
EBNF::ABNF::WSP = T.let(T.unsafe(nil), Regexp)

module EBNF::BNF
  def make_bnf; end
end

class EBNF::Base
  include ::EBNF::BNF
  include ::EBNF::LL1
  include ::EBNF::Native
  include ::EBNF::PEG

  def initialize(input, format: T.unsafe(nil), **options); end

  def ast; end
  def debug(*args, **options); end
  def depth; end
  def dup; end
  def each(kind, &block); end
  def error(*args, **options); end
  def errors; end
  def errors=(_arg0); end
  def find_rule(sym); end
  def progress(*args, **options); end
  def renumber!; end
  def to_html(format: T.unsafe(nil), validate: T.unsafe(nil)); end
  def to_ruby(output = T.unsafe(nil), grammarFile: T.unsafe(nil), mod_name: T.unsafe(nil), **options); end
  def to_s(format: T.unsafe(nil)); end
  def to_sxp(**options); end
  def to_ttl(prefix = T.unsafe(nil), ns = T.unsafe(nil)); end
  def valid?; end
  def validate!; end
end

class EBNF::ISOEBNF
  include ::EBNF::PEG::Parser
  extend ::EBNF::PEG::Parser::ClassMethods

  def initialize(input, **options, &block); end

  def ast; end
end

EBNF::ISOEBNF::FIRST_TERMINAL_CHARACTER = T.let(T.unsafe(nil), Regexp)
EBNF::ISOEBNF::SECOND_TERMINAL_CHARACTER = T.let(T.unsafe(nil), Regexp)
EBNF::ISOEBNF::SPECIAL_SEQUENCE_CHARACTER = T.let(T.unsafe(nil), Regexp)
EBNF::ISOEBNF::TERMINAL_CHARACTER = T.let(T.unsafe(nil), Regexp)
EBNF::ISOEBNF::TERMINAL_CHARACTER_BASE = T.let(T.unsafe(nil), Regexp)

module EBNF::LL1
  def branch; end
  def build_tables; end
  def cleanup; end
  def first; end
  def first_follow(*starts); end
  def follow; end
  def outputTable(io, name, table, indent = T.unsafe(nil)); end
  def pass; end
  def start; end
  def terminals; end
  def to_ruby_ll1(output, **options); end

  private

  def do_production(lhs); end
end

class EBNF::LL1::Lexer
  include ::Enumerable
  include ::EBNF::Unescape

  def initialize(input = T.unsafe(nil), terminals = T.unsafe(nil), **options); end

  def each(&block); end
  def each_token(&block); end
  def first(*types); end
  def input; end
  def input=(_arg0); end
  def lineno; end
  def options; end
  def recover(*types); end
  def shift; end
  def valid?; end
  def whitespace; end

  protected

  def match_token(*types); end
  def scanner; end
  def skip_whitespace; end
  def token(type, value, **options); end

  class << self
    def tokenize(input, terminals, **options, &block); end
    def unescape_codepoints(string); end
    def unescape_string(input); end
  end
end

class EBNF::LL1::Lexer::Error < ::StandardError
  def initialize(message, **options); end

  def input; end
  def lineno; end
  def token; end
end

class EBNF::LL1::Lexer::Terminal
  def initialize(type, regexp, **options); end

  def ==(other); end
  def canonicalize(value); end
  def partial_regexp; end
  def regexp; end
  def type; end

  protected

  def unescape(string); end
end

class EBNF::LL1::Lexer::Token
  def initialize(type, value, **options); end

  def ===(value); end
  def [](key); end
  def inspect; end
  def lineno; end
  def options; end
  def representation; end
  def to_a; end
  def to_hash; end
  def to_s; end
  def type; end
  def value; end
end

module EBNF::LL1::Parser
  mixes_in_class_methods ::EBNF::LL1::Parser::ClassMethods

  def add_prod_data(sym, *values); end
  def add_prod_datum(sym, values); end
  def depth; end
  def lineno; end
  def parse(input = T.unsafe(nil), start = T.unsafe(nil), **options, &block); end
  def prod_data; end

  protected

  def debug(*args, &block); end
  def error(node, message, **options); end
  def progress(node, *args, &block); end
  def warn(node, message, **options); end

  private

  def accept(type_or_value); end
  def first_include?(production, token); end
  def follow_include?(production, token); end
  def get_token(recover = T.unsafe(nil)); end
  def onFinish; end
  def onStart(prod); end
  def onTerminal(prod, token); end

  class << self
    def included(base); end
  end
end

module EBNF::LL1::Parser::ClassMethods
  def eval_with_binding(object); end
  def patterns; end
  def production(term, &block); end
  def production_handlers; end
  def start_handlers; end
  def start_production(term, &block); end
  def terminal(term, regexp, **options, &block); end
  def terminal_handlers; end

  private

  def method_missing(method, *args, &block); end
end

class EBNF::LL1::Parser::Error < ::StandardError
  def initialize(message, **options); end

  def lineno; end
  def production; end
  def token; end
end

class EBNF::LL1::Scanner < ::StringScanner
  def initialize(input, **options); end

  def ensure_buffer_full; end
  def eos?; end
  def input; end
  def lineno; end
  def lineno=(_arg0); end
  def rest; end
  def scan(pattern); end
  def scan_until(pattern); end
  def skip(pattern); end
  def skip_until(pattern); end
  def terminate; end
  def unscan; end

  private

  def encode_utf8(string); end
  def feed_me; end
end

EBNF::LL1::Scanner::HIGH_WATER = T.let(T.unsafe(nil), Integer)
EBNF::LL1::Scanner::LOW_WATER = T.let(T.unsafe(nil), Integer)

module EBNF::Native
  def alt(s); end
  def diff(s); end
  def eachRule(scanner); end
  def expression(s); end
  def postfix(s); end
  def primary(s); end
  def ruleParts(rule); end
  def seq(s); end
  def terminal(s); end
end

module EBNF::PEG
  def make_peg; end
  def to_ruby_peg(output, **options); end
end

module EBNF::PEG::Parser
  mixes_in_class_methods ::EBNF::PEG::Parser::ClassMethods

  def clear_packrat; end
  def debug(*args, &block); end
  def depth; end
  def error(node, message, **options); end
  def find_rule(sym); end
  def onFinish(result); end
  def onStart(prod); end
  def onTerminal(prod, value); end
  def packrat; end
  def parse(input = T.unsafe(nil), start = T.unsafe(nil), rules = T.unsafe(nil), **options, &block); end
  def prod_data; end
  def progress(node, *args, &block); end
  def scanner; end
  def terminal_options(sym); end
  def terminal_regexp(sym); end
  def update_furthest_failure(pos, lineno, token); end
  def warn(node, message, **options); end
  def whitespace; end

  class << self
    def included(base); end
  end
end

module EBNF::PEG::Parser::ClassMethods
  def eval_with_binding(object); end
  def production(term, clear_packrat: T.unsafe(nil), &block); end
  def production_handlers; end
  def start_handlers; end
  def start_options; end
  def start_production(term, **options, &block); end
  def terminal(term, regexp = T.unsafe(nil), **options, &block); end
  def terminal_handlers; end
  def terminal_options; end
  def terminal_regexps; end

  private

  def method_missing(method, *args, &block); end
end

class EBNF::PEG::Parser::Error < ::StandardError
  def initialize(message, **options); end

  def lineno; end
  def production; end
  def rest; end
end

class EBNF::PEG::Parser::Unmatched < ::Struct
  def to_s; end
end

module EBNF::PEG::Rule
  include ::EBNF::Unescape

  def eat_whitespace(input); end
  def parse(input); end
  def parser; end
  def parser=(_arg0); end
  def rept(input, min, max, prod, string_regexp_opts, **options); end
end

class EBNF::Parser
  include ::EBNF::PEG::Parser
  include ::EBNF::Terminals
  extend ::EBNF::PEG::Parser::ClassMethods

  def initialize(input, **options, &block); end

  def ast; end
end

class EBNF::Rule
  def initialize(sym, id, expr, kind: T.unsafe(nil), ebnf: T.unsafe(nil), first: T.unsafe(nil), follow: T.unsafe(nil), start: T.unsafe(nil), top_rule: T.unsafe(nil), cleanup: T.unsafe(nil)); end

  def <=>(other); end
  def ==(other); end
  def add_first(terminals); end
  def add_follow(terminals); end
  def alt?; end
  def build(expr, kind: T.unsafe(nil), cleanup: T.unsafe(nil), **options); end
  def cleanup; end
  def cleanup=(_arg0); end
  def comp; end
  def comp=(_arg0); end
  def eql?(other); end
  def expr; end
  def expr=(_arg0); end
  def first; end
  def first_includes_eps?; end
  def follow; end
  def for_sxp; end
  def id; end
  def id=(_arg0); end
  def inspect; end
  def kind; end
  def kind=(_arg0); end
  def non_terminals(ast, expr = T.unsafe(nil)); end
  def orig; end
  def orig=(_arg0); end
  def pass?; end
  def rule?; end
  def seq?; end
  def start; end
  def start=(_arg0); end
  def starts_with?(sym); end
  def sym; end
  def sym=(_arg0); end
  def symbols(expr = T.unsafe(nil)); end
  def terminal?; end
  def terminals(ast, expr = T.unsafe(nil)); end
  def to_bnf; end
  def to_peg; end
  def to_regexp; end
  def to_ruby; end
  def to_s(**options); end
  def to_sxp(**options); end
  def to_ttl; end
  def translate_codepoints(str); end
  def valid?(ast); end
  def validate!(ast, expr = T.unsafe(nil)); end

  private

  def cclass(txt); end
  def escape_regexp_character_range(character_range); end
  def make_sym_id(variation = T.unsafe(nil)); end
  def ttl_expr(expr, pfx, depth, is_obj = T.unsafe(nil)); end

  class << self
    def from_sxp(sxp); end
  end
end

EBNF::Rule::BNF_OPS = T.let(T.unsafe(nil), Array)
EBNF::Rule::OP_ARGN = T.let(T.unsafe(nil), Hash)
EBNF::Rule::TERM_OPS = T.let(T.unsafe(nil), Array)
module EBNF::Terminals; end
EBNF::Terminals::CHAR = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::HEX = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::LHS = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::O_RANGE = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::PASS = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::POSTFIX = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::RANGE = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::R_CHAR = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::STRING1 = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::STRING2 = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::SYMBOL = T.let(T.unsafe(nil), Regexp)
EBNF::Terminals::SYMBOL_BASE = T.let(T.unsafe(nil), Regexp)

module EBNF::Unescape
  private

  def unescape(string); end
  def unescape_codepoints(string); end
  def unescape_string(input); end

  class << self
    def unescape(string); end
    def unescape_codepoints(string); end
    def unescape_string(input); end
  end
end

EBNF::Unescape::ECHAR = T.let(T.unsafe(nil), Regexp)
EBNF::Unescape::ESCAPE_CHAR4 = T.let(T.unsafe(nil), Regexp)
EBNF::Unescape::ESCAPE_CHAR8 = T.let(T.unsafe(nil), Regexp)
EBNF::Unescape::ESCAPE_CHARS = T.let(T.unsafe(nil), Hash)
EBNF::Unescape::UCHAR = T.let(T.unsafe(nil), Regexp)

module EBNF::VERSION
  class << self
    def to_a; end
    def to_s; end
    def to_str; end
  end
end

EBNF::VERSION::MAJOR = T.let(T.unsafe(nil), String)
EBNF::VERSION::MINOR = T.let(T.unsafe(nil), String)
EBNF::VERSION::STRING = T.let(T.unsafe(nil), String)
EBNF::VERSION::TINY = T.let(T.unsafe(nil), String)
EBNF::VERSION::VERSION_FILE = T.let(T.unsafe(nil), String)

class EBNF::Writer
  def initialize(rules, out: T.unsafe(nil), html: T.unsafe(nil), format: T.unsafe(nil), validate: T.unsafe(nil), **options); end

  protected

  def escape_abnf_hex(u); end
  def escape_ebnf_hex(u); end
  def format_abnf(expr, sep: T.unsafe(nil), embedded: T.unsafe(nil), sensitive: T.unsafe(nil)); end
  def format_abnf_char(c); end
  def format_abnf_range(string); end
  def format_ebnf(expr, sep: T.unsafe(nil), embedded: T.unsafe(nil)); end
  def format_ebnf_char(c); end
  def format_ebnf_range(string); end
  def format_ebnf_string(string, quote = T.unsafe(nil)); end
  def format_isoebnf(expr, sep: T.unsafe(nil), embedded: T.unsafe(nil)); end
  def format_isoebnf_range(string); end

  class << self
    def html(*rules, format: T.unsafe(nil), validate: T.unsafe(nil)); end
    def print(*rules, format: T.unsafe(nil)); end
    def string(*rules, format: T.unsafe(nil)); end
    def write(out, *rules, format: T.unsafe(nil)); end
  end
end

EBNF::Writer::ASCII_ESCAPE_NAMES = T.let(T.unsafe(nil), Array)
EBNF::Writer::ERB_DESC = T.let(T.unsafe(nil), String)
EBNF::Writer::LINE_LENGTH = T.let(T.unsafe(nil), Integer)
EBNF::Writer::LINE_LENGTH_HTML = T.let(T.unsafe(nil), Integer)
module EBNFMeta; end
EBNFMeta::RULES = T.let(T.unsafe(nil), Array)
module ISOEBNFMeta; end
ISOEBNFMeta::RULES = T.let(T.unsafe(nil), Array)