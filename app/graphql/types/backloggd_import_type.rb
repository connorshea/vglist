# frozen_string_literal: true

module Types
  class BackloggdImportType < Types::BaseObject
    description "A user's most recent import from Backloggd."

    field :id, ID, null: false, description: "ID of the import."
    field :username, String, null: false, description: "The Backloggd username the games are imported from."
    field :status, Types::Enums::BackloggdImportStatusType, null: false, description: "Where the import is up to. An import that was dropped partway (for example by a deploy) is reported as `FAILED`."
    field :error_message, String, null: true, description: "Why the import failed, if it did."
    field :added_games, [Types::GameType], null: false, description: "The games that were added to the user's library."
    field :updated_games, [Types::GameType], null: false, description: "Games already in the user's library that had a blank completion status or rating filled in."
    field :unmatched_games, [Types::BackloggdImportUnmatchedGameType], null: false, description: "The games from the Backloggd list that couldn't be matched to a game in the vglist database."
    field :finished_at, GraphQL::Types::ISO8601DateTime, null: true, description: "When the import finished."

    def status
      return 'failed' if (@object.queued? || @object.running?) && !@object.in_progress?

      @object.status
    end

    def error_message
      return "The import stopped partway. Try again." if status == 'failed' && @object.error_message.nil?

      @object.error_message
    end

    def added_games
      @object.added_games.with_attached_cover.order(:name)
    end

    def updated_games
      @object.updated_games.with_attached_cover.order(:name)
    end

    def unmatched_games
      @object.unmatched_games.sort_by { |game| game['name'].to_s.downcase }
    end
  end
end
