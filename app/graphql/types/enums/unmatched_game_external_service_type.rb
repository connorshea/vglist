# frozen_string_literal: true

module Types::Enums
  class UnmatchedGameExternalServiceType < Types::BaseEnum
    description "External services that an Unmatched Game can come from."

    value "STEAM", value: 'Steam', description: 'Imported from the Steam store.'
    value "BACKLOGGD", value: 'Backloggd', description: 'Imported from a Backloggd profile.'
  end
end
