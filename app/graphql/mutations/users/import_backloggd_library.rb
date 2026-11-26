# frozen_string_literal: true

class Mutations::Users::ImportBackloggdLibrary < Mutations::BaseMutation
  description "Starts importing the games from a Backloggd user's public games list into a user's library, matching them by IGDB ID. The import runs in the background: poll `backloggdImport` on the user for its progress and results. **Only available to users importing into their own library.**"

  argument :user_id, ID, required: true, description: "ID of the user whose library the games are imported into."
  argument :backloggd_username, String, required: true, description: "The Backloggd username to import from, or a link to the Backloggd profile."

  field :backloggd_import, Types::BackloggdImportType, null: false, description: "The import that was started."

  def resolve(user_id:, backloggd_username:)
    user = User.find(user_id)
    username = Backloggd::ListFetcher.username_from(backloggd_username)

    # Lock the user so two requests can't both start an import (or both try to
    # create the user's one backloggd_imports row).
    backloggd_import = user.with_lock do
      import = user.backloggd_import || user.build_backloggd_import
      raise GraphQL::ExecutionError, "An import from Backloggd is already running." if import.persisted? && import.in_progress?

      import.update!(
        username: username,
        status: :queued,
        error_message: nil,
        added_game_ids: [],
        updated_game_ids: [],
        unmatched_games: [],
        started_at: nil,
        finished_at: nil
      )
      import
    end
    BackloggdImportJob.perform_later(backloggd_import.id)

    { backloggd_import: backloggd_import }
  rescue Backloggd::ListFetcher::InvalidUsernameError => e
    raise GraphQL::ExecutionError, e.message
  end

  def authorized?(object)
    user = User.find_by(id: object[:user_id])

    return false if user.nil?

    raise GraphQL::ExecutionError, "You aren't allowed to import games for this user." unless UserPolicy.new(@context[:current_user], user).backloggd_import?

    return true
  end
end
