# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `faraday-multipart` gem.
# Please instead update this file by running `bin/tapioca gem faraday-multipart`.

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

Faraday::CompositeReadIO = Faraday::Multipart::CompositeReadIO
Faraday::FilePart = UploadIO
Faraday::METHODS_WITH_BODY = T.let(T.unsafe(nil), Array)
Faraday::METHODS_WITH_QUERY = T.let(T.unsafe(nil), Array)
module Faraday::Multipart; end

class Faraday::Multipart::CompositeReadIO
  def initialize(*parts); end

  def close; end
  def ensure_open_and_readable; end
  def length; end
  def read(length = T.unsafe(nil), outbuf = T.unsafe(nil)); end
  def rewind; end

  private

  def advance_io; end
  def current_io; end
end

Faraday::Multipart::FilePart = UploadIO

class Faraday::Multipart::Middleware < ::Faraday::Request::UrlEncoded
  def initialize(app = T.unsafe(nil), options = T.unsafe(nil)); end

  def call(env); end
  def create_multipart(env, params); end
  def has_multipart?(obj); end
  def part(boundary, key, value); end
  def process_params(params, prefix = T.unsafe(nil), pieces = T.unsafe(nil), &block); end
  def process_request?(env); end
  def unique_boundary; end
end

Faraday::Multipart::Middleware::DEFAULT_BOUNDARY_PREFIX = T.let(T.unsafe(nil), String)

class Faraday::Multipart::ParamPart
  def initialize(value, content_type, content_id = T.unsafe(nil)); end

  def content_id; end
  def content_type; end
  def headers; end
  def to_part(boundary, key); end
  def value; end
end

Faraday::Multipart::Parts = Parts
Faraday::Multipart::VERSION = T.let(T.unsafe(nil), String)
Faraday::Parts = Parts
Faraday::Timer = Timeout
Faraday::UploadIO = UploadIO
Faraday::VERSION = T.let(T.unsafe(nil), String)
