# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `faraday-excon` gem.
# Please instead update this file by running `bin/tapioca sync`.

# typed: true

module Faraday
  class << self
    def default_adapter; end
    def default_adapter=(adapter); end
    def default_connection; end
    def default_connection=(_arg0); end
    def default_connection_options; end
    def default_connection_options=(options); end
    def ignore_env_proxy; end
    def ignore_env_proxy=(_arg0); end
    def lib_path; end
    def lib_path=(_arg0); end
    def new(url = T.unsafe(nil), options = T.unsafe(nil), &block); end
    def require_lib(*libs); end
    def require_libs(*libs); end
    def respond_to_missing?(symbol, include_private = T.unsafe(nil)); end
    def root_path; end
    def root_path=(_arg0); end

    private

    def method_missing(name, *args, &block); end
  end
end

class Faraday::Adapter
  extend(::Faraday::MiddlewareRegistry)
  extend(::Faraday::DependencyLoader)
  extend(::Faraday::Adapter::Parallelism)
  extend(::Faraday::AutoloadHelper)

  def initialize(_app = T.unsafe(nil), opts = T.unsafe(nil), &block); end

  def call(env); end
  def close; end
  def connection(env); end

  private

  def request_timeout(type, options); end
  def save_response(env, status, body, headers = T.unsafe(nil), reason_phrase = T.unsafe(nil)); end
end

Faraday::Adapter::CONTENT_LENGTH = T.let(T.unsafe(nil), String)

class Faraday::Adapter::Excon < ::Faraday::Adapter
  def build_connection(env); end
  def call(env); end
  def read_body(env); end

  private

  def amend_opts_with_proxy_settings!(opts, req); end
  def amend_opts_with_ssl!(opts, ssl); end
  def amend_opts_with_timeouts!(opts, req); end
  def needs_ssl_settings?(env); end
  def opts_from_env(env); end
  def proxy_settings_for_opts(proxy); end
end

Faraday::Adapter::Excon::OPTS_KEYS = T.let(T.unsafe(nil), Array)

Faraday::Adapter::TIMEOUT_KEYS = T.let(T.unsafe(nil), Hash)

module Faraday::Excon
end

Faraday::Excon::VERSION = T.let(T.unsafe(nil), String)

Faraday::FilePart = UploadIO

Faraday::METHODS_WITH_BODY = T.let(T.unsafe(nil), Array)

Faraday::METHODS_WITH_QUERY = T.let(T.unsafe(nil), Array)

Faraday::Parts = Parts

Faraday::Timer = Timeout

Faraday::UploadIO = UploadIO

Faraday::VERSION = T.let(T.unsafe(nil), String)
