class Platform < ApplicationRecord
  has_many :releases
  has_many :games, through: :releases
end
