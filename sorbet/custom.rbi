# typed: strong
# Custom, artisanal RBIs for stuff sorbet and sorbet-rails aren't able to understand yet.

class Devise::RegistrationsController < DeviseController; end
class Devise::ConfirmationsController < DeviseController; end
class Devise::SessionsController < DeviseController; end
class Devise::PasswordsController < DeviseController; end
class DeviseController < ApplicationController; end

module Devise::Controllers::Helpers
  sig { returns(T.nilable(User)) }
  def current_user; end

  sig { params(args: T.untyped, block: T.untyped).returns(T::Boolean) }
  def user_signed_in?(*args, &block); end
end

# This is necessary for current_user to be available inside controllers.
class ActionController::Base
  include ::Devise::Controllers::Helpers
end

class ActionController::Parameters
  # This is a disgusting hack to make `params.require` less verbose for its
  # most common case. I am not proud of what I have done.
  sig { params(key: Symbol).returns(ActionController::Parameters) }
  def typed_require(key); end
end

# Include ActiveStorage::Attached::Model to get the has_one_attached class method.
class ActiveRecord::Base
  include ::ActiveStorage::Attached::Model
end

# Make Sorbet understand that PgSearch::Model mixes in class methods.
module PgSearch::Model
  extend T::Helpers

  mixes_in_class_methods(ClassMethods)
end

# Add modules from Devise to User.
class User
  include ::Devise::Models::Authenticatable
  include ::Devise::Models::Rememberable
  include ::Devise::Models::Recoverable
  include ::Devise::Models::Registerable
  include ::Devise::Models::Validatable
  include ::Devise::Models::Confirmable
  include ::Devise::Models::Trackable
end

class Doorkeeper::ApplicationsController < ApplicationController; end
class Doorkeeper::AuthorizedApplicationsController < ApplicationController; end
class Doorkeeper::AuthorizationsController < ApplicationController; end

# Include PaperTrail so the has_paper_trail method can be used in the
# ActiveModel models. This happens implicitly, but we have to tell Sorbet
# here for it to understand.
class ApplicationRecord
  include PaperTrail::Model
end
