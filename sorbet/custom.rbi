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
end

class ActionController::Parameters
  # This is a disgusting hack to make `params.require` less verbose for its
  # most common case. I am not proud of what I have done.
  sig { params(key: Symbol).returns(ActionController::Parameters) }
  def typed_require(key); end
end
