# typed: strict
class FavoriteGame < ApplicationRecord
  extend T::Sig

  after_create :favorite_game_create_event

  belongs_to :game
  belongs_to :user

  has_many :events, as: :eventable, dependent: :destroy

  validates :user_id, uniqueness: {
    scope: :game_id, message: 'can only favorite a game once'
  }

  private

  sig { void }
  def favorite_game_create_event
    Event.create!(
      eventable_type: 'FavoriteGame',
      eventable_id: id,
      user_id: user.id,
      event_category: :favorite_game
    )
  end
end
