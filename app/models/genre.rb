class Genre < ApplicationRecord
  has_and_belongs_to_many :games

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }
end
