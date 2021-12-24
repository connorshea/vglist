# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `sentry-ruby-core` gem.
# Please instead update this file by running `bin/tapioca gem sentry-ruby-core`.

module Sentry
  class << self
    def add_breadcrumb(breadcrumb, **options); end
    def apply_patches(config); end
    def background_worker; end
    def background_worker=(_arg0); end
    def capture_event(event); end
    def capture_exception(exception, **options, &block); end
    def capture_message(message, **options, &block); end
    def clone_hub_to_current_thread; end
    def configuration(*args, &block); end
    def configure_scope(&block); end
    def csp_report_uri; end
    def exception_locals_tp; end
    def get_current_client; end
    def get_current_hub; end
    def get_current_scope; end
    def get_main_hub; end
    def init(&block); end
    def initialized?; end
    def integrations; end
    def last_event_id; end
    def logger; end
    def railtie_helpers_paths; end
    def railtie_namespace; end
    def railtie_routes_url_helpers(include_path_helpers = T.unsafe(nil)); end
    def register_integration(name, version); end
    def register_patch(&block); end
    def registered_patches; end
    def sdk_meta; end
    def send_event(*args, &block); end
    def set_context(*args, &block); end
    def set_extras(*args, &block); end
    def set_tags(*args, &block); end
    def set_user(*args, &block); end
    def start_transaction(**options); end
    def sys_command(command); end
    def table_name_prefix; end
    def use_relative_model_naming?; end
    def utc_now; end
    def with_scope(&block); end
  end
end

module Sentry::ArgumentCheckingHelper
  private

  def check_argument_type!(argument, expected_type); end
end

class Sentry::BackgroundWorker
  include ::Sentry::LoggingHelper

  def initialize(configuration); end

  def logger; end
  def max_queue; end
  def number_of_threads; end
  def perform(&block); end
  def shutdown; end
  def shutdown_timeout; end
  def shutdown_timeout=(_arg0); end

  private

  def _perform(&block); end
end

class Sentry::Backtrace
  def initialize(lines); end

  def ==(other); end
  def inspect; end
  def lines; end
  def to_s; end

  class << self
    def parse(backtrace, project_root, app_dirs_pattern, &backtrace_cleanup_callback); end
  end
end

Sentry::Backtrace::APP_DIRS_PATTERN = T.let(T.unsafe(nil), Regexp)

class Sentry::Backtrace::Line
  def initialize(file, number, method, module_name, in_app_pattern); end

  def ==(other); end
  def file; end
  def in_app; end
  def in_app_pattern; end
  def inspect; end
  def method; end
  def module_name; end
  def number; end
  def to_s; end

  class << self
    def parse(unparsed_line, in_app_pattern); end
  end
end

Sentry::Backtrace::Line::JAVA_INPUT_FORMAT = T.let(T.unsafe(nil), Regexp)
Sentry::Backtrace::Line::RB_EXTENSION = T.let(T.unsafe(nil), String)
Sentry::Backtrace::Line::RUBY_INPUT_FORMAT = T.let(T.unsafe(nil), Regexp)

class Sentry::Breadcrumb
  def initialize(category: T.unsafe(nil), data: T.unsafe(nil), message: T.unsafe(nil), timestamp: T.unsafe(nil), level: T.unsafe(nil), type: T.unsafe(nil)); end

  def category; end
  def category=(_arg0); end
  def data; end
  def data=(_arg0); end
  def level; end
  def level=(_arg0); end
  def message; end
  def message=(msg); end
  def timestamp; end
  def timestamp=(_arg0); end
  def to_hash; end
  def type; end
  def type=(_arg0); end

  private

  def serialized_data; end
end

Sentry::Breadcrumb::DATA_SERIALIZATION_ERROR_MESSAGE = T.let(T.unsafe(nil), String)

class Sentry::BreadcrumbBuffer
  include ::Enumerable

  def initialize(size = T.unsafe(nil)); end

  def buffer; end
  def buffer=(_arg0); end
  def dup; end
  def each(&block); end
  def empty?; end
  def members; end
  def peek; end
  def record(crumb); end
  def to_hash; end
end

Sentry::BreadcrumbBuffer::DEFAULT_SIZE = T.let(T.unsafe(nil), Integer)

class Sentry::Client
  include ::Sentry::LoggingHelper

  def initialize(configuration); end

  def capture_event(event, scope, hint = T.unsafe(nil)); end
  def configuration; end
  def event_from_exception(exception, hint = T.unsafe(nil)); end
  def event_from_message(message, hint = T.unsafe(nil), backtrace: T.unsafe(nil)); end
  def event_from_transaction(transaction); end
  def generate_sentry_trace(span); end
  def logger; end
  def send_event(event, hint = T.unsafe(nil)); end
  def transport; end

  private

  def dispatch_async_event(async_block, event, hint); end
  def dispatch_background_event(event, hint); end
end

class Sentry::Configuration
  include ::Sentry::CustomInspection
  include ::Sentry::LoggingHelper

  def initialize; end

  def app_dirs_pattern; end
  def app_dirs_pattern=(_arg0); end
  def async; end
  def async=(value); end
  def background_worker_threads; end
  def background_worker_threads=(_arg0); end
  def backtrace_cleanup_callback; end
  def backtrace_cleanup_callback=(_arg0); end
  def before_breadcrumb; end
  def before_breadcrumb=(value); end
  def before_send; end
  def before_send=(value); end
  def breadcrumbs_logger; end
  def breadcrumbs_logger=(logger); end
  def capture_exception_frame_locals; end
  def capture_exception_frame_locals=(_arg0); end
  def context_lines; end
  def context_lines=(_arg0); end
  def csp_report_uri; end
  def debug; end
  def debug=(_arg0); end
  def detect_release; end
  def dsn; end
  def dsn=(value); end
  def enabled_environments; end
  def enabled_environments=(_arg0); end
  def enabled_in_current_env?; end
  def environment; end
  def environment=(environment); end
  def error_messages; end
  def errors; end
  def exception_class_allowed?(exc); end
  def exclude_loggers; end
  def exclude_loggers=(_arg0); end
  def excluded_exceptions; end
  def excluded_exceptions=(_arg0); end
  def gem_specs; end
  def inspect_exception_causes_for_exclusion; end
  def inspect_exception_causes_for_exclusion=(_arg0); end
  def inspect_exception_causes_for_exclusion?; end
  def linecache; end
  def linecache=(_arg0); end
  def logger; end
  def logger=(_arg0); end
  def max_breadcrumbs; end
  def max_breadcrumbs=(_arg0); end
  def project_root; end
  def project_root=(_arg0); end
  def propagate_traces; end
  def propagate_traces=(_arg0); end
  def rack_env_whitelist; end
  def rack_env_whitelist=(_arg0); end
  def rails; end
  def release; end
  def release=(_arg0); end
  def sample_allowed?; end
  def sample_rate; end
  def sample_rate=(_arg0); end
  def send_client_reports; end
  def send_client_reports=(_arg0); end
  def send_default_pii; end
  def send_default_pii=(_arg0); end
  def send_modules; end
  def send_modules=(_arg0); end
  def sending_allowed?; end
  def server=(value); end
  def server_name; end
  def server_name=(_arg0); end
  def skip_rake_integration; end
  def skip_rake_integration=(_arg0); end
  def stacktrace_builder; end
  def traces_sample_rate; end
  def traces_sample_rate=(_arg0); end
  def traces_sampler; end
  def traces_sampler=(_arg0); end
  def tracing_enabled?; end
  def transport; end
  def trusted_proxies; end
  def trusted_proxies=(_arg0); end

  private

  def capture_in_environment?; end
  def check_callable!(name, value); end
  def environment_from_env; end
  def excluded_exception?(incoming_exception); end
  def excluded_exception_classes; end
  def get_exception_class(x); end
  def init_dsn(dsn_string); end
  def matches_exception?(excluded_exception_class, incoming_exception); end
  def run_post_initialization_callbacks; end
  def running_on_heroku?; end
  def safe_const_get(x); end
  def server_name_from_env; end
  def valid?; end

  class << self
    def add_post_initialization_callback(&block); end
    def post_initialization_callbacks; end
  end
end

Sentry::Configuration::HEROKU_DYNO_METADATA_MESSAGE = T.let(T.unsafe(nil), String)
Sentry::Configuration::IGNORE_DEFAULT = T.let(T.unsafe(nil), Array)
Sentry::Configuration::LOG_PREFIX = T.let(T.unsafe(nil), String)
Sentry::Configuration::MODULE_SEPARATOR = T.let(T.unsafe(nil), String)
Sentry::Configuration::RACK_ENV_WHITELIST_DEFAULT = T.let(T.unsafe(nil), Array)
Sentry::Configuration::SKIP_INSPECTION_ATTRIBUTES = T.let(T.unsafe(nil), Array)

module Sentry::CustomInspection
  def inspect; end
end

class Sentry::DSN
  def initialize(dsn_string); end

  def csp_report_uri; end
  def envelope_endpoint; end
  def host; end
  def path; end
  def port; end
  def project_id; end
  def public_key; end
  def scheme; end
  def secret_key; end
  def server; end
  def to_s; end
  def valid?; end
end

Sentry::DSN::PORT_MAP = T.let(T.unsafe(nil), Hash)
Sentry::DSN::REQUIRED_ATTRIBUTES = T.let(T.unsafe(nil), Array)

class Sentry::DummyTransport < ::Sentry::Transport
  def initialize(*_arg0); end

  def events; end
  def events=(_arg0); end
  def send_event(event); end
end

class Sentry::Envelope
  def initialize(headers); end

  def add_item(headers, payload); end
  def to_s; end
end

class Sentry::Error < ::StandardError; end

class Sentry::Event
  include ::Sentry::CustomInspection

  def initialize(configuration:, integration_meta: T.unsafe(nil), message: T.unsafe(nil)); end

  def add_exception_interface(exception); end
  def add_request_interface(env); end
  def add_threads_interface(backtrace: T.unsafe(nil), **options); end
  def backtrace; end
  def backtrace=(_arg0); end
  def breadcrumbs; end
  def breadcrumbs=(_arg0); end
  def configuration; end
  def contexts; end
  def contexts=(_arg0); end
  def environment; end
  def environment=(_arg0); end
  def event_id; end
  def event_id=(_arg0); end
  def exception; end
  def extra; end
  def extra=(_arg0); end
  def fingerprint; end
  def fingerprint=(_arg0); end
  def level; end
  def level=(new_level); end
  def message; end
  def message=(_arg0); end
  def modules; end
  def modules=(_arg0); end
  def platform; end
  def platform=(_arg0); end
  def rack_env=(env); end
  def release; end
  def release=(_arg0); end
  def request; end
  def sdk; end
  def sdk=(_arg0); end
  def server_name; end
  def server_name=(_arg0); end
  def tags; end
  def tags=(_arg0); end
  def threads; end
  def timestamp; end
  def timestamp=(time); end
  def to_hash; end
  def to_json_compatible; end
  def transaction; end
  def transaction=(_arg0); end
  def type; end
  def user; end
  def user=(_arg0); end

  private

  def calculate_real_ip_from_rack(env); end
  def serialize_attributes; end

  class << self
    def get_log_message(event_hash); end
    def get_message_from_exception(event_hash); end
  end
end

Sentry::Event::MAX_MESSAGE_SIZE_IN_BYTES = T.let(T.unsafe(nil), Integer)
Sentry::Event::SERIALIZEABLE_ATTRIBUTES = T.let(T.unsafe(nil), Array)
Sentry::Event::SKIP_INSPECTION_ATTRIBUTES = T.let(T.unsafe(nil), Array)
Sentry::Event::WRITER_ATTRIBUTES = T.let(T.unsafe(nil), Array)

class Sentry::ExceptionInterface < ::Sentry::Interface
  def initialize(values:); end

  def to_hash; end

  class << self
    def build(exception:, stacktrace_builder:); end
  end
end

class Sentry::ExternalError < ::Sentry::Error; end

class Sentry::HTTPTransport < ::Sentry::Transport
  def initialize(*args); end

  def adapter; end
  def conn; end
  def send_data(data); end

  private

  def faraday_opts; end
  def handle_rate_limited_response(headers); end
  def has_rate_limited_header?(headers); end
  def parse_rate_limit_header(rate_limit_header); end
  def set_conn; end
  def should_compress?(data); end
  def ssl_configuration; end
end

Sentry::HTTPTransport::CONTENT_TYPE = T.let(T.unsafe(nil), String)
Sentry::HTTPTransport::DEFAULT_DELAY = T.let(T.unsafe(nil), Integer)
Sentry::HTTPTransport::GZIP_ENCODING = T.let(T.unsafe(nil), String)
Sentry::HTTPTransport::GZIP_THRESHOLD = T.let(T.unsafe(nil), Integer)
Sentry::HTTPTransport::RATE_LIMIT_HEADER = T.let(T.unsafe(nil), String)
Sentry::HTTPTransport::RETRY_AFTER_HEADER = T.let(T.unsafe(nil), String)

class Sentry::Hub
  include ::Sentry::ArgumentCheckingHelper

  def initialize(client, scope); end

  def add_breadcrumb(breadcrumb, hint: T.unsafe(nil)); end
  def bind_client(client); end
  def capture_event(event, **options, &block); end
  def capture_exception(exception, **options, &block); end
  def capture_message(message, **options, &block); end
  def clone; end
  def configuration; end
  def configure_scope(&block); end
  def current_client; end
  def current_scope; end
  def last_event_id; end
  def new_from_top; end
  def pop_scope; end
  def push_scope; end
  def start_transaction(transaction: T.unsafe(nil), custom_sampling_context: T.unsafe(nil), **options); end
  def with_background_worker_disabled(&block); end
  def with_scope(&block); end

  private

  def current_layer; end
end

class Sentry::Hub::Layer
  def initialize(client, scope); end

  def client; end
  def client=(_arg0); end
  def scope; end
end

module Sentry::Integrable
  def capture_exception(exception, **options, &block); end
  def capture_message(message, **options, &block); end
  def integration_name; end
  def register_integration(name:, version:); end
end

class Sentry::Interface
  def to_hash; end

  class << self
    def inherited(klass); end
    def registered; end
  end
end

Sentry::LOGGER_PROGNAME = T.let(T.unsafe(nil), String)

class Sentry::LineCache
  def initialize; end

  def get_file_context(filename, lineno, context); end

  private

  def getline(path, n); end
  def getlines(path); end
  def valid_path?(path); end
end

class Sentry::Logger < ::Logger
  def initialize(*_arg0); end
end

Sentry::Logger::LOG_PREFIX = T.let(T.unsafe(nil), String)
Sentry::Logger::PROGNAME = T.let(T.unsafe(nil), String)

module Sentry::LoggingHelper
  def log_debug(message); end
  def log_error(message, exception, debug: T.unsafe(nil)); end
  def log_info(message); end
  def log_warn(message); end
end

Sentry::META = T.let(T.unsafe(nil), Hash)
module Sentry::Net; end

module Sentry::Net::HTTP
  def do_finish; end
  def do_start; end
  def request(req, body = T.unsafe(nil), &block); end

  private

  def extract_request_info(req); end
  def finish_sentry_span; end
  def from_sentry_sdk?; end
  def record_sentry_breadcrumb(req, res); end
  def record_sentry_span(req, res); end
  def set_sentry_trace_header(req); end
  def start_sentry_span; end
end

Sentry::Net::HTTP::OP_NAME = T.let(T.unsafe(nil), String)
module Sentry::Rack; end

class Sentry::Rack::CaptureExceptions
  def initialize(app); end

  def call(env); end

  private

  def capture_exception(exception); end
  def collect_exception(env); end
  def finish_transaction(transaction, status_code); end
  def start_transaction(env, scope); end
  def transaction_op; end
end

module Sentry::Rake; end

module Sentry::Rake::Application
  def display_error_message(ex); end
end

module Sentry::Rake::Task
  def execute(args = T.unsafe(nil)); end
end

class Sentry::ReleaseDetector
  class << self
    def detect_release(project_root:, running_on_heroku:); end
    def detect_release_from_capistrano(project_root); end
    def detect_release_from_env; end
    def detect_release_from_git; end
    def detect_release_from_heroku(running_on_heroku); end
  end
end

class Sentry::RequestInterface < ::Sentry::Interface
  def initialize(request:); end

  def cookies; end
  def cookies=(_arg0); end
  def data; end
  def data=(_arg0); end
  def env; end
  def env=(_arg0); end
  def headers; end
  def headers=(_arg0); end
  def method; end
  def method=(_arg0); end
  def query_string; end
  def query_string=(_arg0); end
  def url; end
  def url=(_arg0); end

  private

  def encode_to_utf_8(value); end
  def filter_and_format_env(env); end
  def filter_and_format_headers(env); end
  def is_server_protocol?(key, value, protocol_version); end
  def is_skippable_header?(key); end
  def read_data_from(request); end

  class << self
    def build(env:); end
    def clean_env(env); end
  end
end

Sentry::RequestInterface::CONTENT_HEADERS = T.let(T.unsafe(nil), Array)
Sentry::RequestInterface::IP_HEADERS = T.let(T.unsafe(nil), Array)
Sentry::RequestInterface::MAX_BODY_LIMIT = T.let(T.unsafe(nil), Integer)
Sentry::RequestInterface::REQUEST_ID_HEADERS = T.let(T.unsafe(nil), Array)
Sentry::SENTRY_TRACE_HEADER_NAME = T.let(T.unsafe(nil), String)

class Sentry::Scope
  include ::Sentry::ArgumentCheckingHelper

  def initialize(max_breadcrumbs: T.unsafe(nil)); end

  def add_breadcrumb(breadcrumb); end
  def add_event_processor(&block); end
  def apply_to_event(event, hint = T.unsafe(nil)); end
  def breadcrumbs; end
  def clear; end
  def clear_breadcrumbs; end
  def contexts; end
  def dup; end
  def event_processors; end
  def extra; end
  def fingerprint; end
  def get_span; end
  def get_transaction; end
  def level; end
  def rack_env; end
  def set_context(key, value); end
  def set_contexts(contexts_hash); end
  def set_extra(key, value); end
  def set_extras(extras_hash); end
  def set_fingerprint(fingerprint); end
  def set_level(level); end
  def set_rack_env(env); end
  def set_span(span); end
  def set_tag(key, value); end
  def set_tags(tags_hash); end
  def set_transaction_name(transaction_name); end
  def set_user(user_hash); end
  def span; end
  def tags; end
  def transaction_name; end
  def transaction_names; end
  def update_from_options(contexts: T.unsafe(nil), extra: T.unsafe(nil), tags: T.unsafe(nil), user: T.unsafe(nil), level: T.unsafe(nil), fingerprint: T.unsafe(nil)); end
  def update_from_scope(scope); end
  def user; end

  protected

  def breadcrumbs=(_arg0); end
  def contexts=(_arg0); end
  def event_processors=(_arg0); end
  def extra=(_arg0); end
  def fingerprint=(_arg0); end
  def level=(_arg0); end
  def rack_env=(_arg0); end
  def span=(_arg0); end
  def tags=(_arg0); end
  def transaction_names=(_arg0); end
  def user=(_arg0); end

  private

  def set_default_value; end
  def set_new_breadcrumb_buffer; end

  class << self
    def os_context; end
    def runtime_context; end
  end
end

Sentry::Scope::ATTRIBUTES = T.let(T.unsafe(nil), Array)

class Sentry::SingleExceptionInterface < ::Sentry::Interface
  include ::Sentry::CustomInspection

  def initialize(exception:, stacktrace: T.unsafe(nil)); end

  def module; end
  def stacktrace; end
  def thread_id; end
  def to_hash; end
  def type; end
  def value; end

  class << self
    def build_with_stacktrace(exception:, stacktrace_builder:); end
  end
end

Sentry::SingleExceptionInterface::MAX_LOCAL_BYTES = T.let(T.unsafe(nil), Integer)
Sentry::SingleExceptionInterface::OMISSION_MARK = T.let(T.unsafe(nil), String)
Sentry::SingleExceptionInterface::PROBLEMATIC_LOCAL_VALUE_REPLACEMENT = T.let(T.unsafe(nil), String)
Sentry::SingleExceptionInterface::SKIP_INSPECTION_ATTRIBUTES = T.let(T.unsafe(nil), Array)

class Sentry::Span
  def initialize(description: T.unsafe(nil), op: T.unsafe(nil), status: T.unsafe(nil), trace_id: T.unsafe(nil), parent_span_id: T.unsafe(nil), sampled: T.unsafe(nil), start_timestamp: T.unsafe(nil), timestamp: T.unsafe(nil)); end

  def data; end
  def deep_dup; end
  def description; end
  def finish; end
  def get_trace_context; end
  def op; end
  def parent_span_id; end
  def sampled; end
  def set_data(key, value); end
  def set_description(description); end
  def set_http_status(status_code); end
  def set_op(op); end
  def set_status(status); end
  def set_tag(key, value); end
  def set_timestamp(timestamp); end
  def span_id; end
  def span_recorder; end
  def span_recorder=(_arg0); end
  def start_child(**options); end
  def start_timestamp; end
  def status; end
  def tags; end
  def timestamp; end
  def to_hash; end
  def to_sentry_trace; end
  def trace_id; end
  def transaction; end
  def transaction=(_arg0); end
  def with_child_span(**options, &block); end
end

Sentry::Span::STATUS_MAP = T.let(T.unsafe(nil), Hash)

class Sentry::StacktraceBuilder
  def initialize(project_root:, app_dirs_pattern:, linecache:, context_lines:, backtrace_cleanup_callback: T.unsafe(nil)); end

  def app_dirs_pattern; end
  def backtrace_cleanup_callback; end
  def build(backtrace:, &frame_callback); end
  def context_lines; end
  def linecache; end
  def project_root; end

  private

  def convert_parsed_line_into_frame(line); end
  def parse_backtrace_lines(backtrace); end
end

class Sentry::StacktraceInterface
  def initialize(frames:); end

  def frames; end
  def inspect; end
  def to_hash; end
end

class Sentry::StacktraceInterface::Frame < ::Sentry::Interface
  def initialize(project_root, line); end

  def abs_path; end
  def abs_path=(_arg0); end
  def compute_filename; end
  def context_line; end
  def context_line=(_arg0); end
  def filename; end
  def filename=(_arg0); end
  def function; end
  def function=(_arg0); end
  def in_app; end
  def in_app=(_arg0); end
  def lineno; end
  def lineno=(_arg0); end
  def module; end
  def module=(_arg0); end
  def post_context; end
  def post_context=(_arg0); end
  def pre_context; end
  def pre_context=(_arg0); end
  def set_context(linecache, context_lines); end
  def to_hash(*args); end
  def to_s; end
  def vars; end
  def vars=(_arg0); end

  private

  def longest_load_path; end
  def under_project_root?; end
end

Sentry::THREAD_LOCAL = T.let(T.unsafe(nil), Symbol)

class Sentry::ThreadsInterface
  def initialize(crashed: T.unsafe(nil), stacktrace: T.unsafe(nil)); end

  def to_hash; end

  class << self
    def build(backtrace:, stacktrace_builder:, **options); end
  end
end

class Sentry::Transaction < ::Sentry::Span
  include ::Sentry::LoggingHelper

  def initialize(hub:, name: T.unsafe(nil), parent_sampled: T.unsafe(nil), **options); end

  def configuration; end
  def deep_dup; end
  def finish(hub: T.unsafe(nil)); end
  def hub; end
  def logger; end
  def name; end
  def parent_sampled; end
  def set_initial_sample_decision(sampling_context:); end
  def to_hash; end

  protected

  def init_span_recorder(limit = T.unsafe(nil)); end

  private

  def generate_transaction_description; end

  class << self
    def from_sentry_trace(sentry_trace, hub: T.unsafe(nil), **options); end
  end
end

Sentry::Transaction::MESSAGE_PREFIX = T.let(T.unsafe(nil), String)
Sentry::Transaction::SENTRY_TRACE_REGEXP = T.let(T.unsafe(nil), Regexp)

class Sentry::Transaction::SpanRecorder
  def initialize(max_length); end

  def add(span); end
  def max_length; end
  def spans; end
end

Sentry::Transaction::UNLABELD_NAME = T.let(T.unsafe(nil), String)

class Sentry::TransactionEvent < ::Sentry::Event
  def initialize(configuration:, integration_meta: T.unsafe(nil), message: T.unsafe(nil)); end

  def contexts; end
  def contexts=(_arg0); end
  def environment; end
  def environment=(_arg0); end
  def event_id; end
  def event_id=(_arg0); end
  def extra; end
  def extra=(_arg0); end
  def level; end
  def modules; end
  def modules=(_arg0); end
  def platform; end
  def platform=(_arg0); end
  def release; end
  def release=(_arg0); end
  def sdk; end
  def sdk=(_arg0); end
  def server_name; end
  def server_name=(_arg0); end
  def spans; end
  def spans=(_arg0); end
  def start_timestamp; end
  def start_timestamp=(time); end
  def tags; end
  def tags=(_arg0); end
  def timestamp; end
  def to_hash; end
  def transaction; end
  def transaction=(_arg0); end
  def type; end
  def user; end
  def user=(_arg0); end
end

Sentry::TransactionEvent::SERIALIZEABLE_ATTRIBUTES = T.let(T.unsafe(nil), Array)
Sentry::TransactionEvent::TYPE = T.let(T.unsafe(nil), String)
Sentry::TransactionEvent::WRITER_ATTRIBUTES = T.let(T.unsafe(nil), Array)

class Sentry::Transport
  include ::Sentry::LoggingHelper

  def initialize(configuration); end

  def discarded_events; end
  def encode(event); end
  def generate_auth_header; end
  def is_rate_limited?(item_type); end
  def last_client_report_sent; end
  def logger; end
  def rate_limits; end
  def record_lost_event(reason, item_type); end
  def send_data(data, options = T.unsafe(nil)); end
  def send_event(event); end

  private

  def fetch_pending_client_report; end
  def get_item_type(event_hash); end
end

Sentry::Transport::CLIENT_REPORT_INTERVAL = T.let(T.unsafe(nil), Integer)
Sentry::Transport::CLIENT_REPORT_REASONS = T.let(T.unsafe(nil), Array)

class Sentry::Transport::Configuration
  def initialize; end

  def encoding; end
  def encoding=(_arg0); end
  def faraday_builder; end
  def faraday_builder=(_arg0); end
  def http_adapter; end
  def http_adapter=(_arg0); end
  def open_timeout; end
  def open_timeout=(_arg0); end
  def proxy; end
  def proxy=(_arg0); end
  def ssl; end
  def ssl=(_arg0); end
  def ssl_ca_file; end
  def ssl_ca_file=(_arg0); end
  def ssl_verification; end
  def ssl_verification=(_arg0); end
  def timeout; end
  def timeout=(_arg0); end
  def transport_class; end
  def transport_class=(klass); end
end

Sentry::Transport::PROTOCOL_VERSION = T.let(T.unsafe(nil), String)
Sentry::Transport::USER_AGENT = T.let(T.unsafe(nil), String)
module Sentry::Utils; end

module Sentry::Utils::ExceptionCauseChain
  class << self
    def exception_to_array(exception); end
  end
end

class Sentry::Utils::RealIp
  def initialize(remote_addr: T.unsafe(nil), client_ip: T.unsafe(nil), real_ip: T.unsafe(nil), forwarded_for: T.unsafe(nil), trusted_proxies: T.unsafe(nil)); end

  def calculate_ip; end
  def ip; end

  protected

  def filter_trusted_proxy_addresses(ips); end
  def ips_from(header); end
end

Sentry::Utils::RealIp::LOCAL_ADDRESSES = T.let(T.unsafe(nil), Array)

module Sentry::Utils::RequestId
  class << self
    def read_from(env); end
  end
end

Sentry::Utils::RequestId::REQUEST_ID_HEADERS = T.let(T.unsafe(nil), Array)
Sentry::VERSION = T.let(T.unsafe(nil), String)