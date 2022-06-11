# typed: strict
class User < ApplicationRecord
  extend FriendlyId
  include PgSearch::Model
  include GlobalSearchable
  include Searchable

  after_create :on_user_creation

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  has_many :game_purchases
  has_many :games, through: :game_purchases

  # Relationship to FavoriteGame records.
  has_many :favorite_games, dependent: :destroy
  # Relationship to the _Game_ records that the user has favorited.
  has_many :favorited_games,
    through: :favorite_games,
    source: :game

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
  # Old events
  has_many :events, dependent: :destroy
  # New events
  has_many :new_events, class_name: 'Views::NewEvent'
  has_many :game_purchase_events, class_name: 'Events::GamePurchaseEvent', dependent: :destroy
  has_many :relationship_events, class_name: 'Events::RelationshipEvent', dependent: :destroy
  has_many :user_events, class_name: 'Events::UserEvent', dependent: :destroy
  has_many :favorite_game_events, class_name: 'Events::FavoriteGameEvent', dependent: :destroy

  # Users have an event for their creation.
  # Old events.
  has_many :events, as: :eventable, dependent: :destroy
  # New events
  has_many :user_events, foreign_key: :eventable_id, class_name: 'Events::UserEvent', dependent: :destroy

  # Users create wikidata and steam blocklist entries.
  # We want to keep the entry even if the user that created it is deleted.
  has_many :wikidata_blocklists, dependent: :nullify
  has_many :steam_blocklists, dependent: :nullify

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

  # Only use one of the pre-set sizes for these images.
  AVATAR_SIZES = T.let(
    {
      small: [80, 80],
      medium: [150, 150],
      large: [300, 300]
    },
    T::Hash[Symbol, [Integer, Integer]]
  )

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
    # Must be between 3 and 20 characters
    length: { minimum: 3, maximum: 20 },
    # Allow letters, numbers, disallow _ and . at the start or end,
    # disallow _ or . next to each other or themselves.
    # Based on https://stackoverflow.com/a/51937085/7143763
    format: /\A(?=.{3,20}\z)[a-zA-Z0-9]+(?:[._][a-zA-Z0-9]+)*\z/,
    uniqueness: true

  # Validate that the username is not reserved when the user is created.
  validate :username_not_reserved, on: :create

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

  global_searchable :username
  searchable :username

  sig { returns(T.nilable(String)) }
  def api_token
    return nil if encrypted_api_token.nil?

    EncryptionService.decrypt(T.must(encrypted_api_token))
  end

  sig { params(value: String).void }
  def api_token=(value)
    self.encrypted_api_token = EncryptionService.encrypt(value)
  end

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

  # Verify that the token passed into the application matches the user's
  # actual token.
  sig { params(token: T.nilable(String)).returns(T::Boolean) }
  def verify_api_token!(token)
    # Return false if the user attempts to pass a nil token. This prevents
    # other users from hijacking an account if the account doesn't have
    # a token.
    return false if token.nil?

    api_token == token
  end

  # Generate an avatar variant with a specific size, size must be a Symbol
  # matching one of the keys in `User::AVATAR_SIZES`.
  sig do
    params(size: Symbol).returns(
      T.nilable(
        T.any(
          ActiveStorage::Variant,
          ActiveStorage::VariantWithRecord
        )
      )
    )
  end
  def sized_avatar(size)
    width, height = AVATAR_SIZES[size]
    avatar&.variant(
      resize_to_fill: [width, height],
      gravity: 'Center',
      crop: "#{width}x#{height}+0+0"
    )
  end

  private

  # Usernames that are reserved so they cannot be used.
  RESERVED_USERNAMES = T.let(%w[
    mod moderator admin administrator
    new edit index session login logout
    sign_out sign_up sign_in search
    system username
  ].freeze, T::Array[String])

  # Validate that the username isn't reserved for use by the system.
  sig { void }
  def username_not_reserved
    errors.add(:username, "is reserved by the system") if RESERVED_USERNAMES.include?(username.downcase)
  end

  sig { void }
  def on_user_creation
    Events::UserEvent.create!(
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
