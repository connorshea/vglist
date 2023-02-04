# typed: strict
module Types::Enums
  class ActivityFeedType < Types::BaseEnum
    description "Options for filtering events in the activity feed."

    value "GLOBAL", value: 'global', description: "Events from everyone."
    value "FOLLOWING", value: 'following', description: "Events from the current user and anyone they follow."
  end
end
