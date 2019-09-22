module Types
  class GameType < Types::BaseObject
    field :name, String, null: false
    field :description, String, null: true
    field :wikidata_id, Integer, null: true
    field :pcgamingwiki_id, String, null: true
    field :mobygames_id, String, null: true
  end
end
