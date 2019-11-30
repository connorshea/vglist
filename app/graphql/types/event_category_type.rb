# typed: strict
module Types
  class EventCategoryType < Types::BaseEnum
    description "Category types for events in the Activity Feed."

    value "ADD_TO_LIBRARY", value: 'add_to_library', description: "Event for a user adding a game to their library."
    value "CHANGE_COMPLETION_STATUS", value: 'change_completion_status', description: "Event for a user updating the completion status of a game."
    value "FAVORITE_GAME", value: 'favorite_game', description: "Event for a user favoriting a game."
    value "NEW_USER", value: 'new_user', description: "Event for user creation."
    value "FOLLOWING", value: 'following', description: "Event for a user following another user."
  end
end
