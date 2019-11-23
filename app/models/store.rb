# typed: strict
class Store < ApplicationRecord
  include PgSearch::Model

  validates :name,
    presence: true,
    length: { maximum: 120 }

  # Search scope specific to series.
  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
