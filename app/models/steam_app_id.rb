# typed: strong
class SteamAppId < ApplicationRecord
  belongs_to :game

  validates :app_id,
    uniqueness: true,
    allow_nil: false,
    numericality: {
      only_integer: true,
      allow_nil: true,
      greater_than: 0
    }
end
