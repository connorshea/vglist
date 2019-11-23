# typed: strict
class Store < ApplicationRecord
  include PgSearch::Model

  has_many :game_purchase_stores
  has_many :game_purchases, through: :game_purchase_stores, source: :game_purchase

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
