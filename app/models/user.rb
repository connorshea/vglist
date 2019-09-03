# typed: false
class User < ApplicationRecord
  extend FriendlyId

  after_create :user_create_event

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  has_many :game_purchases
  has_many :games, through: :game_purchases

  # Users have favorites of various types.
  has_many :favorite_games, dependent: :destroy

  # Users can follow other users.
  has_many :active_relationships, class_name: 'Relationship', foreign_key: 'follower_id', dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed

  # Users can also be followed by other users.
  has_many :passive_relationships, class_name: 'Relationship', foreign_key: 'followed_id'
  has_many :followers, through: :passive_relationships, source: :follower

  # Users have activity feed events.
  has_many :events, dependent: :destroy

  # Users have an event for their creation.
  has_many :events, as: :eventable, dependent: :destroy

  # External accounts, e.g. Steam. Can be changed to a has_many association if
  # other external account types are added later.
  has_one :external_account, dependent: :destroy

  has_one_attached :avatar

  friendly_id :username, use: [:slugged, :finders]

  # Users have roles that can be used to define what actions they're allowed
  # to perform. Default should be 'member'.
  enum role: {
    member: 0,
    moderator: 1,
    admin: 2
  }

  # Account privacy
  enum privacy: {
    public_account: 0,
    private_account: 1
  }

  validates :username,
    # Username is required
    presence: true,
    # Must be between 4 and 20 characters
    length: { minimum: 4, maximum: 20 },
    # Allow letters, numbers, disallow _ and . at the start or end,
    # disallow _ or . next to each other or themselves.
    # Based on https://stackoverflow.com/a/51937085/7143763
    format: /\A(?=.{4,20}\z)[a-zA-Z0-9]+(?:[._][a-zA-Z0-9]+)*\z/,
    uniqueness: true

  validates :slug,
    presence: true,
    uniqueness: true

  # Bio can be blank.
  validates :bio,
    length: { maximum: 1000 }

  # Every user must have a role.
  validates :role,
    presence: true

  validates :avatar,
    attached: false,
    content_type: ['image/png', 'image/jpg', 'image/jpeg'],
    size: { less_than: 3.megabytes }

  private

  def user_create_event
    Event.create!(
      eventable_type: 'User',
      eventable_id: id,
      user_id: id,
      event_category: :new_user
    )
  end
end
