# frozen_string_literal: true

# Fetches a user's Backloggd list and adds its games to their library,
# recording the outcome on their BackloggdImport.
class BackloggdImportJob < ApplicationJob
  queue_as :default

  def perform(backloggd_import_id)
    # Claim the import in one statement, so a second copy of the job (or one
    # for an import that's already finished) does nothing.
    now = Time.current
    claimed = BackloggdImport.where(id: backloggd_import_id, status: :queued)
                             .update_all(status: BackloggdImport.statuses[:running], started_at: now, updated_at: now, error_message: nil) # rubocop:disable Rails/SkipsModelValidations
    return if claimed.zero?

    backloggd_import = BackloggdImport.find(backloggd_import_id)
    entries = Backloggd::ListFetcher.new(backloggd_import.username).entries
    return fail!(backloggd_import, no_games_message(backloggd_import.username)) if entries.empty?

    result = Backloggd::ImportService.new(user: backloggd_import.user, entries: entries).call

    backloggd_import.update!(
      status: :succeeded,
      finished_at: Time.current,
      added_game_ids: result.created.pluck(:game_id),
      updated_game_ids: result.updated.pluck(:game_id),
      unmatched_games: result.unmatched.map { |game| { name: game.name, slug: game.slug } }
    )
  rescue Backloggd::ListFetcher::BlockedError
    fail!(backloggd_import, "Backloggd didn't let vglist read the profile. Try again later.")
  rescue Backloggd::ListFetcher::Error => e
    fail!(backloggd_import, e.message)
  rescue StandardError => e
    Sentry.capture_exception(e)
    fail!(backloggd_import, 'Something went wrong while importing from Backloggd.')
  end

  private

  def no_games_message(username)
    "Couldn't find any games on #{username}'s Backloggd profile. Make sure the username is right " \
      "and that the profile has games under Played, Playing or Backlog."
  end

  def fail!(backloggd_import, message)
    backloggd_import&.update!(status: :failed, error_message: message, finished_at: Time.current)
  end
end
