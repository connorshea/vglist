# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rackup` gem.
# Please instead update this file by running `bin/tapioca gem rackup`.


module Rack
  class << self
    def release; end
    def version; end
  end
end

Rack::Handler = Rackup::Handler
Rack::Server = Rackup::Server
module Rackup; end

# *Handlers* connect web servers with Rack.
#
# Rackup includes Handlers for WEBrick and CGI.
#
# Handlers usually are activated by calling <tt>MyHandler.run(myapp)</tt>.
# A second optional hash can be passed to include server-specific
# configuration.
module Rackup::Handler
  class << self
    def [](name); end
    def default; end
    def get(name); end

    # Select first available Rack handler given an `Array` of server names.
    # Raises `LoadError` if no handler was found.
    #
    #   > pick ['puma', 'webrick']
    #   => Rackup::Handler::WEBrick
    #
    # @raise [LoadError]
    def pick(server_names); end

    # Register a named handler class.
    def register(name, klass); end

    # Transforms server-name constants to their canonical form as filenames,
    # then tries to require them but silences the LoadError if not found
    #
    # Naming convention:
    #
    #   Foo # => 'foo'
    #   FooBar # => 'foo_bar.rb'
    #   FooBAR # => 'foobar.rb'
    #   FOObar # => 'foobar.rb'
    #   FOOBAR # => 'foobar.rb'
    #   FooBarBaz # => 'foo_bar_baz.rb'
    def require_handler(prefix, const_name); end
  end
end

class Rackup::Handler::CGI
  include ::Rack

  class << self
    def run(app, **options); end
    def send_body(body); end
    def send_headers(status, headers); end
    def serve(app); end
  end
end

Rackup::Handler::RACKUP_HANDLER = T.let(T.unsafe(nil), String)
Rackup::Handler::RACK_HANDLER = T.let(T.unsafe(nil), String)
Rackup::Handler::SERVER_NAMES = T.let(T.unsafe(nil), Array)

class Rackup::Handler::WEBrick < ::WEBrick::HTTPServlet::AbstractServlet
  # @return [WEBrick] a new instance of WEBrick
  def initialize(server, app); end

  def service(req, res); end

  class << self
    # @yield [@server]
    def run(app, **options); end

    def shutdown; end
    def valid_options; end
  end
end

# This handles mapping the WEBrick request to a Rack input stream.
class Rackup::Handler::WEBrick::Input
  include ::Rackup::Stream::Reader

  # @return [Input] a new instance of Input
  def initialize(request); end

  def close; end

  private

  # Read one chunk from the request body.
  def read_next; end
end

class Rackup::Server
  # Options may include:
  # * :app
  #     a rack application to run (overrides :config and :builder)
  # * :builder
  #     a string to evaluate a Rack::Builder from
  # * :config
  #     a rackup configuration file path to load (.ru)
  # * :environment
  #     this selects the middleware that will be wrapped around
  #     your application. Default options available are:
  #       - development: CommonLogger, ShowExceptions, and Lint
  #       - deployment: CommonLogger
  #       - none: no extra middleware
  #     note: when the server is a cgi server, CommonLogger is not included.
  # * :server
  #     choose a specific Rackup::Handler, e.g. cgi, fcgi, webrick
  # * :daemonize
  #     if truthy, the server will daemonize itself (fork, detach, etc)
  #     if :noclose, the server will not close STDOUT/STDERR
  # * :pid
  #     path to write a pid file after daemonize
  # * :Host
  #     the host address to bind to (used by supporting Rackup::Handler)
  # * :Port
  #     the port to bind to (used by supporting Rackup::Handler)
  # * :AccessLog
  #     webrick access log options (or supporting Rackup::Handler)
  # * :debug
  #     turn on debug output ($DEBUG = true)
  # * :warn
  #     turn on warnings ($-w = true)
  # * :include
  #     add given paths to $LOAD_PATH
  # * :require
  #     require the given libraries
  #
  # Additional options for profiling app initialization include:
  # * :heapfile
  #     location for ObjectSpace.dump_all to write the output to
  # * :profile_file
  #     location for CPU/Memory (StackProf) profile output (defaults to a tempfile)
  # * :profile_mode
  #     StackProf profile mode (cpu|wall|object)
  #
  # @return [Server] a new instance of Server
  def initialize(options = T.unsafe(nil)); end

  def app; end
  def default_options; end
  def middleware; end
  def options; end

  # Sets the attribute options
  #
  # @param value the value to set the attribute options to.
  def options=(_arg0); end

  def server; end
  def start(&block); end

  private

  def build_app(app); end
  def build_app_and_options_from_config; end
  def build_app_from_string; end
  def check_pid!; end
  def daemonize_app; end
  def exit_with_pid(pid); end
  def handle_profiling(heapfile, profile_mode, filename); end
  def make_profile_name(filename); end
  def opt_parser; end
  def parse_options(args); end
  def wrapped_app; end
  def write_pid; end

  class << self
    def default_middleware_by_environment; end
    def logging_middleware; end
    def middleware; end

    # Start a new rack server (like running rackup). This will parse ARGV and
    # provide standard ARGV rackup options, defaulting to load 'config.ru'.
    #
    # Providing an options hash will prevent ARGV parsing and will not include
    # any default options.
    #
    # This method can be used to very easily launch a CGI application, for
    # example:
    #
    #  Rack::Server.start(
    #    :app => lambda do |e|
    #      [200, {'content-type' => 'text/html'}, ['hello world']]
    #    end,
    #    :server => 'cgi'
    #  )
    #
    # Further options available here are documented on Rack::Server#initialize
    def start(options = T.unsafe(nil)); end
  end
end

class Rackup::Server::Options
  def handler_opts(options); end
  def parse!(args); end
end

# The input stream is an IO-like object which contains the raw HTTP POST data. When applicable, its external encoding must be “ASCII-8BIT” and it must be opened in binary mode, for Ruby 1.9 compatibility. The input stream must respond to gets, each, read and rewind.
class Rackup::Stream
  include ::Rackup::Stream::Reader

  # @raise [ArgumentError]
  # @return [Stream] a new instance of Stream
  def initialize(input = T.unsafe(nil), output = T.unsafe(nil)); end

  def <<(buffer); end

  # Close the input and output bodies.
  def close(error = T.unsafe(nil)); end

  def close_read; end

  # close must never be called on the input stream. huh?
  def close_write; end

  # Whether the stream has been closed.
  #
  # @return [Boolean]
  def closed?; end

  # Whether there are any output chunks remaining?
  #
  # @return [Boolean]
  def empty?; end

  def flush; end

  # Returns the value of attribute input.
  def input; end

  # Returns the value of attribute output.
  def output; end

  def write(buffer); end
  def write_nonblock(buffer); end

  private

  def read_next; end
end

# This provides a read-only interface for data, which is surprisingly tricky to implement correctly.
module Rackup::Stream::Reader
  def each; end
  def gets; end

  # read behaves like IO#read. Its signature is read([length, [buffer]]). If given, length must be a non-negative Integer (>= 0) or nil, and buffer must be a String and may not be nil. If length is given and not nil, then this method reads at most length bytes from the input stream. If length is not given or nil, then this method reads all data until EOF. When EOF is reached, this method returns nil if length is given and not nil, or “” if length is not given or is nil. If buffer is given, then the read data will be placed into buffer instead of a newly created String object.
  #
  # @param length [Integer] the amount of data to read
  # @param buffer [String] the buffer which will receive the data
  # @return a buffer containing the data
  def read(length = T.unsafe(nil), buffer = T.unsafe(nil)); end

  def read_nonblock(length, buffer = T.unsafe(nil)); end

  # Read at most `length` bytes from the stream. Will avoid reading from the underlying stream if possible.
  def read_partial(length = T.unsafe(nil)); end
end

Rackup::VERSION = T.let(T.unsafe(nil), String)
