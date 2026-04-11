# frozen_string_literal: true

class SteamBlocklist < ApplicationRecord
  belongs_to :user, optional: true

  validates :steam_app_id,
    presence: true,
    uniqueness: true

  validates :name,
    presence: true,
    length: { maximum: 120 }
end
