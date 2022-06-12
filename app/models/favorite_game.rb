# typed: strict
class FavoriteGame < ApplicationRecord
  after_create :favorite_game_create_event

  belongs_to :game
  belongs_to :user

  # Old events
  has_many :events, as: :eventable, dependent: :destroy
  # New events
  has_many :favorite_game_events, foreign_key: :eventable_id, inverse_of: :eventable, class_name: 'Events::FavoriteGameEvent', dependent: :destroy

  validates :user_id, uniqueness: {
    scope: :game_id, message: 'can only favorite a game once'
  }

  private

  sig { void }
  def favorite_game_create_event
    Events::FavoriteGameEvent.create!(
      eventable_id: id,
      user_id: user.id,
      event_category: :favorite_game
    )
  end
end
