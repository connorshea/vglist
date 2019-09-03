# typed: true
class Relationship < ApplicationRecord
  # The user that's following the other.
  belongs_to :follower, class_name: 'User'
  # The user being followed.
  belongs_to :followed, class_name: 'User'

  validates_presence_of :follower_id
  validates_presence_of :followed_id

  validates :follower_id,
    uniqueness: { scope: :followed_id }
end
