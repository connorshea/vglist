# typed: strict
module Types
  class ActivityFeedType < Types::BaseEnum
    value "GLOBAL", value: 'global', description: "Events from everyone."
    value "FOLLOWING", value: 'following', description: "Events from the current user and anyone they follow."
  end
end
