class Release < ApplicationRecord
  belongs_to :game
  belongs_to :platform

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }
end
