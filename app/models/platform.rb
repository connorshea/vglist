class Platform < ApplicationRecord
  has_many :releases
  has_many :games, through: :releases

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }
end
