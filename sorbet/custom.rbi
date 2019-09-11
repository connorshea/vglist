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
