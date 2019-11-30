# typed: true
module Types
  class UserType < Types::BaseObject
    description "User accounts on vglist"

    field :id, ID, null: false, description: "ID of the user."
    field :username, String, null: false, description: "Username of the user."
    field :bio, String, null: true, description: "User profile description, aka 'bio'."
    field :slug, String, null: false, description: "The user's slug, used for their profile URL."
    field :role, UserRoleType, null: false, description: "User permission level."
    field :privacy, UserPrivacyType, null: false, description: "The user's level of privacy."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this user was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this user was last updated."

    # Associations
    field :game_purchases, GamePurchaseType.connection_type, null: true, description: "Games in this user's library."
    field :followers, UserType.connection_type, null: true, description: "Users that are following this user."
    field :following, UserType.connection_type, null: true, description: "Users that this user is following."
    field :favorite_games, GameType.connection_type, null: true, description: "Games that this user has favorited."
    field :activity, EventType.connection_type, null: true, description: "Activity Events that refer to this user."

    field :avatar_url, String, null: true, description: "URL for the user's avatar image. `null` means the user has the default avatar."

    sig { returns(T.nilable(Event::ActiveRecord_Relation)) }
    def activity
      return nil unless user_visible?

      Event.recently_created
           .joins(:user)
           .where(user_id: @object.id)
    end

    # This causes an N+2 query, figure out a better way to do this.
    # https://github.com/rmosolgo/graphql-ruby/issues/1777
    sig { returns(T.nilable(String)) }
    def avatar_url
      attachment = @object.avatar_attachment
      return if attachment.nil?

      Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end

    # Extremely cursed metaprogramming that protects private users from having their details exposed
    # if the UserPolicy wants to prevent it.
    sig { params(field_name: Symbol).returns(T.untyped) }
    def handler(field_name)
      return @object.public_send(field_name) if user_visible?

      nil
    end

    # Define a method for each of these fields, to forward the correct info onto the handler method.
    # This overrides the default field accessors to make sure the viewer is actually supposed to
    # see this information.
    [:bio, :game_purchases, :followers, :following, :favorite_games].each do |meth_name|
      define_method(meth_name) do
        # Sorbet is dumb and doesn't realize the handler method exists, I guess.
        T.unsafe(self).handler(meth_name)
      end
    end

    sig { returns(T::Boolean) }
    def user_visible?
      # Short-circuit if the user has a public account, to prevent instantiating
      # a UserPolicy and all that.
      return @object.public_account? || UserPolicy.new(@context[:current_user], @object).show?
    end
  end
end
