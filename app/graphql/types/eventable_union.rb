# typed: true
class Types::EventableUnion < Types::BaseUnion
  description "Objects which may be the subject of events."
  possible_types Types::UserType,
                 Types::GamePurchaseType,
                 Types::RelationshipType,
                 Types::FavoriteGameType

  def self.resolve_type(object, _context)
    case object
    when User
      Types::UserType
    when GamePurchase
      Types::GamePurchaseType
    when Relationship
      Types::RelationshipType
    when FavoriteGame
      Types::FavoriteGameType
    end
  end
end
