# typed: strong
class WikidataBlocklist < ApplicationRecord
  validates :wikidata_id,
    presence: true,
    uniqueness: true
end
