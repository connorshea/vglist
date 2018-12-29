class Game < ApplicationRecord
  has_many :relases
  has_many :platforms, through: :releases
  has_many :game_purchases
  has_many :purchasers, through: :game_purchases,
    class_name: "User", foreign_key: :user_id
end
