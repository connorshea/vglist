class Favorite < ApplicationRecord
  belongs_to :favoritable, polymorphic: true
  belongs_to :user, inverse_of: :favorites

  scope :games, -> { where(favoritable_type: 'Game') }

  validates :user_id, uniqueness: {
    scope: [:favoritable_id, :favoritable_type],
    message: 'can only favorite an item once'
  }
end
