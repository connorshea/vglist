# frozen_string_literal: true

# A user's most recent import from Backloggd. Fetching a Backloggd list takes a
# while, so the import runs in BackloggdImportJob and the results are kept here
# for the settings page to show.
class BackloggdImport < ApplicationRecord
  belongs_to :user

  enum :status, {
    queued: 0,
    running: 1,
    succeeded: 2,
    failed: 3
  }

  # Jobs run in-process, so a deploy can drop one mid-import. An import that
  # hasn't moved in this long is treated as abandoned and can be started again.
  STALE_AFTER = 30.minutes

  validates :username, presence: true, length: { maximum: 40 }

  def in_progress?
    (queued? || running?) && updated_at > STALE_AFTER.ago
  end

  def added_games
    Game.where(id: added_game_ids)
  end

  def updated_games
    Game.where(id: updated_game_ids)
  end
end
