# frozen_string_literal: true

module Types
  module SearchResults
    class GameSearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "A game search result."

      field :cover_url, String, null: true, description: "URL for the game's cover image. `null` means the game has no associated cover." do
        argument :size, Enums::GameCoverSizeType, required: false, default_value: :small, description: "The size of the game cover image being requested."
      end
      field :developer_name, String, null: true, description: 'The name of the game\'s developer, will choose the first if there are multiple developers.'
      field :release_date, GraphQL::Types::ISO8601Date, null: true, description: 'The release date of the game, if one exists.'

      def cover_url(size:)
        cover = game&.sized_cover(size)
        return if cover.nil?

        Rails.application.routes.url_helpers.rails_representation_url(cover)
      end

      def developer_name
        game&.developers&.first&.name
      end

      def release_date
        game&.release_date
      end

      private

      def game
        @context[:preloaded_games]&.dig(@object.searchable_id)
      end
    end
  end
end
