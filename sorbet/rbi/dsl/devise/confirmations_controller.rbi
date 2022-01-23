# typed: strict

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Devise::ConfirmationsController`.
# Please instead update this file by running `bin/tapioca dsl Devise::ConfirmationsController`.

class Devise::ConfirmationsController
  sig { returns(HelperProxy) }
  def helpers; end

  module HelperMethods
    include ::Webpacker::Helper
    include ::ActionController::Base::HelperMethods
    include ::ApplicationHelper
    include ::ActivityHelper
    include ::GamesHelper
    include ::SettingsHelper
    include ::UsersHelper
    include ::Doorkeeper::DashboardHelper
    include ::DeviseHelper
    include ::Pundit::Helper
    include ::ApplicationController::HelperMethods

    sig { returns(T.untyped) }
    def devise_mapping; end

    sig { returns(T.untyped) }
    def resource; end

    sig { returns(T.untyped) }
    def resource_class; end

    sig { returns(T.untyped) }
    def resource_name; end

    sig { returns(T.untyped) }
    def resource_params; end

    sig { returns(T.untyped) }
    def scope_name; end

    sig { returns(T.untyped) }
    def signed_in_resource; end
  end

  class HelperProxy < ::ActionView::Base
    include HelperMethods
  end
end
