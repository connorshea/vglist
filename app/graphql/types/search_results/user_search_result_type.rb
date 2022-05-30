# typed: true
module Types
  module SearchResults
    class UserSearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "A user search result."

      field :avatar_url, String, null: true, description: "URL for the user's avatar image. `null` means the user has the default avatar." do
        argument :size, Enums::UserAvatarSizeType, required: false, default_value: :small, description: "The size of the avatar image being requested."
      end
      field :slug, String, null: false, description: "The slug for usage defining the user's profile URL."

      # This causes an N+2 query, figure out a better way to do this.
      # https://github.com/rmosolgo/graphql-ruby/issues/1777
      sig { params(size: Symbol).returns(T.nilable(String)) }
      def avatar_url(size:)
        avatar = User.find(@object.searchable_id).sized_avatar(size)
        return if avatar.nil?

        Rails.application.routes.url_helpers.rails_representation_url(avatar)
      end

      sig { returns(String) }
      def slug
        User.find(@object.searchable_id).slug
      end
    end
  end
end
