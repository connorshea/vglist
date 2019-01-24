class Company < ApplicationRecord
  include PgSearch

  has_many :release_developers
  has_many :developed_releases, through: :release_developers, source: :release

  has_many :release_publishers
  has_many :published_releases, through: :release_publishers, source: :release

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
