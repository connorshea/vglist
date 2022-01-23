# typed: strict

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `SettingsController`.
# Please instead update this file by running `bin/tapioca dsl SettingsController`.

class SettingsController
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

    sig { returns(T.untyped) }
    def error; end

    sig { params(record: T.untyped).returns(T.untyped) }
    def policy(record); end

    sig { params(scope: T.untyped).returns(T.untyped) }
    def pundit_policy_scope(scope); end

    sig { returns(T.untyped) }
    def pundit_user; end

    sig { returns(T.untyped) }
    def success; end
  end

  class HelperProxy < ::ActionView::Base
    include HelperMethods
  end
end
