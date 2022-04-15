# typed: true
# Model for tracking games that were imported via Steam Import (and potentially
# other importers later) that couldn't be matched to a game on vglist.
class UnmatchedGame < ApplicationRecord
  belongs_to :user, optional: true

  # Prevent the same user from creating unmatched game records multiple times
  # for the same game.
  validates :user_id, uniqueness: {
    scope: [:external_service_id, :external_service_name]
  }
end
