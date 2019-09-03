# typed: strong
# Custom, artisanal RBIs for stuff sorbet and sorbet-rails aren't able to understand yet.

class Devise::RegistrationsController < DeviseController; end
class Devise::ConfirmationsController < DeviseController; end
class Devise::SessionsController < DeviseController; end
class Devise::PasswordsController < DeviseController; end
class DeviseController < ApplicationController; end

# Make current_user available in GamesHelper and UsersHelper.
module GamesHelper
  include Devise::Controllers::Helpers
end

module UsersHelper
  include Devise::Controllers::Helpers
end
