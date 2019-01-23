class Company < ApplicationRecord
  include PgSearch

  has_many :developed_releases, through: :release_developer, source: :release
  has_many :published_releases, through: :release_publisher, source: :release

  validates :name,
    presence: true,
    length: { maximum: 120 }

  validates :description,
    length: { maximum: 1000 }

  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
