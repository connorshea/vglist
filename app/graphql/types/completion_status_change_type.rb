# frozen_string_literal: true

module Types
  class CompletionStatusChangeType < Types::BaseObject
    description "The completion status of a game in a user's library before and after a change."

    field :before, Enums::GamePurchaseCompletionStatusType, null: true, description: "The completion status before the change. `null` means the game had no completion status."
    field :after, Enums::GamePurchaseCompletionStatusType, null: true, description: "The completion status after the change. `null` means the completion status was cleared."
  end
end
