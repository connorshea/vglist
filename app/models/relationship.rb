# typed: true
class Relationship < ApplicationRecord
  # The user that's following the other.
  belongs_to :follower, class_name: 'User'
  # The user being followed.
  belongs_to :followed, class_name: 'User'

  validates :followed_id,
    presence: true

  validates :follower_id,
    presence: true,
    uniqueness: { scope: :followed_id }
end
