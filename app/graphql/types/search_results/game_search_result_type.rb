# typed: true
module Types
  module SearchResults
    class GameSearchResultType < Types::BaseObject
      implements Types::SearchResultInterface

      description "A game search result."

      field :cover_url, String, null: true, description: "URL for the game's cover image. `null` means the game has no associated cover." do
        argument :size, GameCoverSizeType, required: false, default_value: :small, description: "The size of the game cover image being requested."
      end
      field :developer_name, String, null: true, description: 'The name of the game\'s developer, will choose the first if there are multiple developers.'
      field :release_date, GraphQL::Types::ISO8601Date, null: true, description: 'The release date of the game, if one exists.'

      # TODO: This causes an N+2 query, figure out a better way to do this.
      # https://github.com/rmosolgo/graphql-ruby/issues/1777
      sig { params(size: Symbol).returns(T.nilable(String)) }
      def cover_url(size:)
        cover = Game.find(@object.searchable_id).sized_cover(size)
        return if cover.nil?

        Rails.application.routes.url_helpers.rails_representation_url(cover)
      end

      sig { returns(T.nilable(String)) }
      def developer_name
        Game.find(@object.searchable_id).developers.first&.name
      end

      sig { returns(T.nilable(Date)) }
      def release_date
        Game.find(@object.searchable_id).release_date
      end
    end
  end
end
