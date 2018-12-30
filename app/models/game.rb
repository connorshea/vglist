class Game < ApplicationRecord
  has_many :releases
  has_many :platforms, through: :releases
  has_many :game_purchases
  has_many :purchasers, through: :game_purchases,
    class_name: "User", foreign_key: :user_id

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }
end
