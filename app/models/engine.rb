class Engine < ApplicationRecord
  validates :name,
    presence: true,
    length: { maximum: 120 }
end
