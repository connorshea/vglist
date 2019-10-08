# typed: true
class Types::EventableUnion < Types::BaseUnion
  description "Objects which may be the subject of events."
  possible_types Types::UserType,
                 Types::GamePurchaseType,
                 Types::RelationshipType,
                 Types::FavoriteGameType

  def self.resolve_type(object, _context)
    if object.is_a?(User)
      Types::UserType
    elsif object.is_a?(GamePurchase)
      Types::GamePurchaseType
    elsif object.is_a?(Relationship)
      Types::RelationshipType
    elsif object.is_a?(FavoriteGame)
      Types::FavoriteGameType
    end
  end
end
