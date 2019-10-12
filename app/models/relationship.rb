# typed: strict
class Relationship < ApplicationRecord
  extend T::Sig

  after_create :create_follow_event

  # The user that's following the other.
  belongs_to :follower, class_name: 'User'
  # The user being followed.
  belongs_to :followed, class_name: 'User'

  has_many :events, as: :eventable, dependent: :destroy

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
    Event.create!(
      eventable_type: 'Relationship',
      eventable_id: id,
      user_id: follower_id,
      event_category: :following
    )
  end
end
