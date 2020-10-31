# typed: true
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

  validate :app_id_not_blocklisted

  protected

  # Prevent the game from using a Steam App ID which has been blocklisted.
  def app_id_not_blocklisted
    return unless app_id.present? && SteamBlocklist.pluck(:steam_app_id).include?(app_id)

    errors.add(:app_id, "is blocklisted")
  end
end
