# typed: strict
class User < ApplicationRecord
  extend T::Sig
  extend FriendlyId
  include PgSearch::Model

  after_create :on_user_creation

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  acts_as_token_authenticatable

  has_many :game_purchases
  has_many :games, through: :game_purchases

  # Users have favorites of various types.
  has_many :favorite_games, dependent: :destroy

  # Users can follow other users.
  has_many :active_relationships,
    class_name: 'Relationship',
    foreign_key: 'follower_id',
    inverse_of: :follower,
    dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed

  # Users can also be followed by other users.
  has_many :passive_relationships,
    class_name: 'Relationship',
    foreign_key: 'followed_id',
    inverse_of: :followed,
    dependent: :destroy
  has_many :followers, through: :passive_relationships, source: :follower

  # Users have activity feed events.
  has_many :events, dependent: :destroy

  # Users have an event for their creation.
  has_many :events, as: :eventable, dependent: :destroy

  # Users create wikidata blocklist entries.
  # We want to keep the entry even if the user that created it is deleted.
  has_many :wikidata_blocklists, dependent: :nullify

  # rubocop:disable Rails/InverseOf
  # Users have Doorkeeper access tokens and grants.
  has_many :access_grants,
    class_name: 'Doorkeeper::AccessGrant',
    foreign_key: :resource_owner_id,
    dependent: :destroy

  has_many :access_tokens,
    class_name: 'Doorkeeper::AccessToken',
    foreign_key: :resource_owner_id,
    dependent: :destroy
  # rubocop:enable Rails/InverseOf

  has_many :oauth_applications,
    class_name: 'Doorkeeper::Application',
    as: :owner

  # External accounts, e.g. Steam. Can be changed to a has_many association if
  # other external account types are added later.
  has_one :external_account, dependent: :destroy

  has_one_attached :avatar

  friendly_id :username, use: [:slugged, :finders]

  # Sort by most games owned.
  scope :most_games, -> {
    left_joins(:game_purchases)
      .group(:id)
      .order(Arel.sql('count(game_purchases.user_id) desc nulls last'))
  }

  # Sort by most followers.
  scope :most_followers, -> {
    left_joins(:passive_relationships)
      .group(:id)
      .order(Arel.sql('count(relationships.followed_id) desc nulls last'))
  }

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
    size: { less_than: 3.megabytes },
    aspect_ratio: :square

  # Include users in global search.
  multisearchable against: [:username]

  # Search scope specific to users.
  pg_search_scope :search,
    against: [:username],
    using: {
      tsearch: { prefix: true }
    }

  # Make sure the user isn't banned when logging in with Devise.
  sig { returns(T.nilable(T::Boolean)) }
  def active_for_authentication?
    super && !banned?
  end

  # If the user is determined to be inactive by `active_for_authentication?`,
  # this is the name of the message that will be returned.
  sig { returns(Symbol) }
  def inactive_message
    banned? ? :account_banned : super
  end

  private

  sig { void }
  def on_user_creation
    Event.create!(
      eventable_type: 'User',
      eventable_id: id,
      user_id: id,
      event_category: :new_user
    )

    # Follow User #1 by default (aka connor)
    return if id == 1 || User.where(id: 1).empty?

    Relationship.create!(
      follower_id: id,
      followed: User.find(1)
    )
  end
end
