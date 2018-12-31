class Release < ApplicationRecord
  belongs_to :game
  belongs_to :platform
  has_many :release_purchases
  has_many :purchasers, through: :release_purchases, source: :user

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }
end
