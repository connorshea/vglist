# typed: strict
class Relationship < ApplicationRecord
  after_create :create_follow_event

  # The user that's following the other.
  belongs_to :follower, class_name: 'User'
  # The user being followed.
  belongs_to :followed, class_name: 'User'

  # Old events
  has_many :events, as: :eventable, dependent: :destroy
  # New events
  has_many :relationship_events, foreign_key: :eventable_id, inverse_of: :eventable, class_name: 'Events::RelationshipEvent', dependent: :destroy

  validates :followed_id,
    presence: true

  validates :follower_id,
    presence: true,
    uniqueness: { scope: :followed_id }

  validate :user_cannot_follow_self

  private

  sig { void }
  def user_cannot_follow_self
    errors.add(:follower_id, "can't follow themselves") if follower_id == followed_id
  end

  # Create an event when following a user.
  sig { void }
  def create_follow_event
    Events::RelationshipEvent.create!(
      eventable_id: id,
      user_id: follower_id,
      event_category: :following
    )
  end
end
