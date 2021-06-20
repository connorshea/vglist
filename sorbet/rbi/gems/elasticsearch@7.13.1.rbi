# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `elasticsearch` gem.
# Please instead update this file by running `bin/tapioca sync`.

# typed: true

module Elastic
  class << self
    def client_meta_version; end
  end
end

Elastic::ELASTICSEARCH_SERVICE_VERSION = T.let(T.unsafe(nil), Array)
module Elasticsearch; end
module Elasticsearch::Transport; end

class Elasticsearch::Transport::Client
  include ::Elasticsearch::API::Common
  include ::Elasticsearch::API
  include ::Elasticsearch::API::Shutdown
  include ::Elasticsearch::API::Features
  include ::Elasticsearch::API::DanglingIndices
  include ::Elasticsearch::API::Remote
  include ::Elasticsearch::API::Cat
  include ::Elasticsearch::API::Tasks
  include ::Elasticsearch::API::Snapshot
  include ::Elasticsearch::API::Ingest
  include ::Elasticsearch::API::Indices
  include ::Elasticsearch::API::Nodes
  include ::Elasticsearch::API::Cluster
  include ::Elasticsearch::API::Actions
  include ::Elasticsearch::Transport::MetaHeader

  def initialize(arguments = T.unsafe(nil), &block); end

  def perform_request(method, path, params = T.unsafe(nil), body = T.unsafe(nil), headers = T.unsafe(nil)); end
  def transport; end
  def transport=(_arg0); end

  private

  def __auto_detect_adapter; end
  def __encode(api_key); end
  def __extract_hosts(hosts_config); end
  def __parse_host(host); end
  def add_header(header); end
  def extract_cloud_creds(arguments); end
  def set_api_key; end
  def set_compatibility_header; end
end

Elasticsearch::Transport::Client::DEFAULT_CLOUD_PORT = T.let(T.unsafe(nil), Integer)
Elasticsearch::Transport::Client::DEFAULT_HOST = T.let(T.unsafe(nil), String)
Elasticsearch::Transport::Client::DEFAULT_LOGGER = T.let(T.unsafe(nil), Proc)
Elasticsearch::Transport::Client::DEFAULT_PORT = T.let(T.unsafe(nil), Integer)
Elasticsearch::Transport::Client::DEFAULT_TRACER = T.let(T.unsafe(nil), Proc)
Elasticsearch::Transport::Client::DEFAULT_TRANSPORT_CLASS = Elasticsearch::Transport::Transport::HTTP::Faraday
Elasticsearch::Transport::VERSION = T.let(T.unsafe(nil), String)
Elasticsearch::VERSION = T.let(T.unsafe(nil), String)