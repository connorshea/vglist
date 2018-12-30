class Release < ApplicationRecord
  belongs_to :game
  belongs_to :platform
  has_many :release_purchases
  has_many :purchasers, through: :release_purchases,
    class_name: "User", foreign_key: :user_id

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }
end
