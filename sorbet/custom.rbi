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

class Doorkeeper::ApplicationsController < ApplicationController; end
class Doorkeeper::AuthorizedApplicationsController < ApplicationController; end
class Doorkeeper::AuthorizationsController < ApplicationController; end

# Dumb hack to work around an issue in Sorbet with nilable blocks not
# letting you use `T.proc.bind`.
# https://github.com/sorbet/sorbet/issues/498
# This allows `argument` to be used within field blocks, even though the
# actual solution should look more like this:
#
# ```ruby
# module GraphQL::Schema::Member::HasFields
#   sig do
#     params(
#       args: T.untyped,
#       kwargs: T.untyped,
#       block: T.nilable(T.proc.bind(GraphQL::Schema::Field).void)
#     ).returns(T.untyped)
#   end
#   def field(*args, **kwargs, &block); end
# end
# ```
#
# Note that this will only impact QueryType, and will need to be done for every
# class where we want to use fields with arguments.
# class Types::QueryType < Types::BaseObject
#   extend GraphQL::Schema::Member::HasArguments
# end

# Add types for custom Faker methods defined in `config/initializers/faker.rb`.
class Faker::Game
  sig { returns(String) }
  def self.company; end

  sig { returns(String) }
  def self.engine; end

  sig { returns(String) }
  def self.series; end

  sig { returns(String) }
  def self.store; end
end
