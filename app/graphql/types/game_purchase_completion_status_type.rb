# typed: strict
module Types
  class GamePurchaseCompletionStatusType < Types::BaseEnum
    description "Completion Status options for game purchases (games in a user's library)."

    value "UNPLAYED", value: 'unplayed', description: "The game is unplayed."
    value "IN_PROGRESS", value: 'in_progress', description: "The game is currently being played."
    value "DROPPED", value: 'dropped', description: "The game was dropped without being completed."
    value "COMPLETED", value: 'completed', description: "The game has been completed."
    value "FULLY_COMPLETED", value: 'fully_completed', description: "The game is 100% complete, e.g. with all achievements unlocked."
    value "NOT_APPLICABLE", value: 'not_applicable', description: "The game cannot be completed."
    value "PAUSED", value: 'paused', description: "The game is incomplete and not being played, but the user intends to come back to play it again later."
  end
end
