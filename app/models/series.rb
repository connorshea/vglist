class Series < ApplicationRecord
  include PgSearch

  has_many :games

  validates :name,
    presence: true,
    length: { maximum: 120 }

  pg_search_scope :search,
    against: [:name],
    using: {
      tsearch: { prefix: true }
    }
end
