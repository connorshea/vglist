# frozen_string_literal: true

module Types
  module SearchResults
    class UserSearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "A user search result."

      field :avatar_url, String, null: true, description: "URL for the user's avatar image. `null` means the user has the default avatar." do
        argument :size, Enums::UserAvatarSizeType, required: false, default_value: :small, description: "The size of the avatar image being requested."
      end
      field :slug, String, null: false, description: "The slug for usage defining the user's profile URL."

      def avatar_url(size:)
        avatar = user&.sized_avatar(size)
        return if avatar.nil?

        Rails.application.routes.url_helpers.rails_representation_url(avatar)
      end

      def slug
        resolved_user = user
        raise GraphQL::ExecutionError, "User not found for search result #{@object.searchable_id}" if resolved_user.nil?

        resolved_user.slug
      end

      private

      def user
        @user ||= @context[:preloaded_users]&.dig(@object.searchable_id) || User.find_by(id: @object.searchable_id)
      end
    end
  end
end
