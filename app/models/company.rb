class Company < ApplicationRecord
  has_many :developed_releases, through: :release_developer, source: :release
  has_many :published_releases, through: :release_publisher, source: :release

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }
end
