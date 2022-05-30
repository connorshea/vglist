# typed: strict
module Types::Enums
  class UnmatchedGameExternalServiceType < Types::BaseEnum
    description "External services that an Unmatched Game can come from, currently only Steam."

    value "STEAM", value: 'Steam'
  end
end
