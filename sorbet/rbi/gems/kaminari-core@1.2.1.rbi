# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `kaminari-core` gem.
# Please instead update this file by running `tapioca sync`.

# typed: true

module Kaminari
  class << self
    def config; end
    def configure; end
    def paginate_array(array, limit: T.unsafe(nil), offset: T.unsafe(nil), total_count: T.unsafe(nil), padding: T.unsafe(nil)); end
  end
end

class Kaminari::Config
  def initialize; end

  def default_per_page; end
  def default_per_page=(_arg0); end
  def left; end
  def left=(_arg0); end
  def max_pages; end
  def max_pages=(_arg0); end
  def max_per_page; end
  def max_per_page=(_arg0); end
  def outer_window; end
  def outer_window=(_arg0); end
  def page_method_name; end
  def page_method_name=(_arg0); end
  def param_name; end
  def param_name=(_arg0); end
  def params_on_first_page; end
  def params_on_first_page=(_arg0); end
  def right; end
  def right=(_arg0); end
  def window; end
  def window=(_arg0); end
end

module Kaminari::ConfigurationMethods
  extend(::ActiveSupport::Concern)

  mixes_in_class_methods(::Kaminari::ConfigurationMethods::ClassMethods)
end

module Kaminari::ConfigurationMethods::ClassMethods
  def default_per_page; end
  def max_pages(val = T.unsafe(nil)); end
  def max_pages_per(val); end
  def max_paginates_per(val); end
  def max_per_page; end
  def paginates_per(val); end
end

class Kaminari::Engine < ::Rails::Engine
end

module Kaminari::Helpers
end

class Kaminari::Helpers::FirstPage < ::Kaminari::Helpers::Tag
  include(::Kaminari::Helpers::Link)

  def page; end
end

class Kaminari::Helpers::Gap < ::Kaminari::Helpers::Tag
end

module Kaminari::Helpers::HelperMethods
  include(::Kaminari::Helpers::UrlHelper)

  def link_to_next_page(scope, name, **options); end
  def link_to_prev_page(scope, name, **options); end
  def link_to_previous_page(scope, name, **options); end
  def page_entries_info(collection, entry_name: T.unsafe(nil)); end
  def paginate(scope, paginator_class: T.unsafe(nil), template: T.unsafe(nil), **options); end
  def rel_next_prev_link_tags(scope, options = T.unsafe(nil)); end
end

class Kaminari::Helpers::LastPage < ::Kaminari::Helpers::Tag
  include(::Kaminari::Helpers::Link)

  def page; end
end

module Kaminari::Helpers::Link
  def page; end
  def to_s(locals = T.unsafe(nil)); end
  def url; end
end

class Kaminari::Helpers::NextPage < ::Kaminari::Helpers::Tag
  include(::Kaminari::Helpers::Link)

  def initialize(template, params: T.unsafe(nil), param_name: T.unsafe(nil), theme: T.unsafe(nil), views_prefix: T.unsafe(nil), **options); end

  def page; end
end

Kaminari::Helpers::PARAM_KEY_EXCEPT_LIST = T.let(T.unsafe(nil), Array)

class Kaminari::Helpers::Page < ::Kaminari::Helpers::Tag
  include(::Kaminari::Helpers::Link)

  def page; end
  def to_s(locals = T.unsafe(nil)); end
end

class Kaminari::Helpers::Paginator < ::Kaminari::Helpers::Tag
  include(::ActionView::Context)

  def initialize(template, window: T.unsafe(nil), outer_window: T.unsafe(nil), left: T.unsafe(nil), right: T.unsafe(nil), inner_window: T.unsafe(nil), **options); end

  def each_page; end
  def each_relevant_page; end
  def first_page_tag; end
  def gap_tag; end
  def last_page_tag; end
  def next_page_tag; end
  def page_tag(page); end
  def prev_page_tag; end
  def render(&block); end
  def to_s; end

  private

  def method_missing(name, *args, &block); end
  def relevant_pages(options); end
end

class Kaminari::Helpers::Paginator::PageProxy
  include(::Comparable)

  def initialize(options, page, last); end

  def +(other); end
  def -(other); end
  def <=>(other); end
  def current?; end
  def display_tag?; end
  def first?; end
  def inside_window?; end
  def last?; end
  def left_outer?; end
  def next?; end
  def number; end
  def out_of_range?; end
  def prev?; end
  def rel; end
  def right_outer?; end
  def single_gap?; end
  def to_i; end
  def to_s; end
  def was_truncated?; end
end

class Kaminari::Helpers::PrevPage < ::Kaminari::Helpers::Tag
  include(::Kaminari::Helpers::Link)

  def initialize(template, params: T.unsafe(nil), param_name: T.unsafe(nil), theme: T.unsafe(nil), views_prefix: T.unsafe(nil), **options); end

  def page; end
end

class Kaminari::Helpers::Tag
  def initialize(template, params: T.unsafe(nil), param_name: T.unsafe(nil), theme: T.unsafe(nil), views_prefix: T.unsafe(nil), **options); end

  def page_url_for(page); end
  def to_s(locals = T.unsafe(nil)); end

  private

  def params_for(page); end
  def partial_path; end
end

module Kaminari::Helpers::UrlHelper
  def next_page_path(scope, options = T.unsafe(nil)); end
  def next_page_url(scope, options = T.unsafe(nil)); end
  def path_to_next_page(scope, options = T.unsafe(nil)); end
  def path_to_next_url(scope, options = T.unsafe(nil)); end
  def path_to_prev_page(scope, options = T.unsafe(nil)); end
  def path_to_previous_page(scope, options = T.unsafe(nil)); end
  def prev_page_path(scope, options = T.unsafe(nil)); end
  def prev_page_url(scope, options = T.unsafe(nil)); end
  def previous_page_path(scope, options = T.unsafe(nil)); end
  def previous_page_url(scope, options = T.unsafe(nil)); end
  def url_to_prev_page(scope, options = T.unsafe(nil)); end
  def url_to_previous_page(scope, options = T.unsafe(nil)); end
end

module Kaminari::PageScopeMethods
  def current_page; end
  def current_per_page; end
  def first_page?; end
  def last_page?; end
  def max_paginates_per(new_max_per_page); end
  def next_page; end
  def out_of_range?; end
  def padding(num); end
  def per(num, max_per_page: T.unsafe(nil)); end
  def prev_page; end
  def total_pages; end
end

class Kaminari::PaginatableArray < ::Array
  include(::Kaminari::ConfigurationMethods::ClassMethods)

  def initialize(original_array = T.unsafe(nil), limit: T.unsafe(nil), offset: T.unsafe(nil), total_count: T.unsafe(nil), padding: T.unsafe(nil)); end

  def entry_name(options = T.unsafe(nil)); end
  def limit(num); end
  def limit_value; end
  def limit_value=(_arg0); end
  def offset(num); end
  def offset_value; end
  def offset_value=(_arg0); end
  def page(num = T.unsafe(nil)); end
  def total_count; end
end

Kaminari::PaginatableArray::ENTRY = T.let(T.unsafe(nil), String)

class Kaminari::Railtie < ::Rails::Railtie
end

class Kaminari::ZeroPerPageOperation < ::ZeroDivisionError
end
