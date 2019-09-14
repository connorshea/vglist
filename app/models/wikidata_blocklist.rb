# typed: strong
class WikidataBlocklist < ApplicationRecord
  belongs_to :user, optional: true

  validates :wikidata_id,
    presence: true,
    uniqueness: true

  validates :name,
    presence: true,
    length: { maximum: 120 }
end
