# frozen_string_literal: true

module Types
  # NOTE: We intentionally do not expose the email field here, as it is considered sensitive information.
  class UserType < Types::BaseObject
    description "User accounts on vglist"

    field :id, ID, null: false, description: "ID of the user."
    field :username, String, null: false, description: "Username of the user."
    field :bio, String, null: true, description: "User profile description, aka 'bio'."
    field :slug, String, null: false, description: "The user's slug, used for their profile URL."
    field :role, Enums::UserRoleType, null: false, description: "User permission level."
    field :privacy, Enums::UserPrivacyType, null: false, description: "The user's level of privacy."
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this user was first created."
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When this user was last updated."
    field :banned, Boolean, null: false, description: "Whether this user has been banned."

    field :library_statistics, LibraryStatisticsType, null: false, description: "Aggregate statistics for this user's library, calculated across the whole library."

    # Associations
    field :game_purchases, GamePurchaseType.connection_type, null: false, description: "Games in this user's library." do
      argument :completion_status, Enums::GamePurchaseCompletionStatusType, required: false, description: "Only return the games with this completion status."
      argument :no_completion_status, Boolean, required: false, description: "When `true`, only return the games that have no completion status. Combining it with `completionStatus` matches nothing."
      argument :search, String, required: false, description: "Only return the games whose name contains this string, case-insensitively."
      argument :sort_by, Enums::GamePurchaseSortType, required: false, description: "The order to sort the games in, if any."
      argument :platform_ids, [ID], required: false, description: "Only return the games the user owns on at least one of these platforms."
      argument :store_ids, [ID], required: false, description: "Only return the games the user owns from at least one of these stores."
      argument :min_rating, Integer, required: false, description: "Only return the games the user rated at least this highly, out of 100. Unrated games are left out."
      argument :max_rating, Integer, required: false, description: "Only return the games the user rated at most this highly, out of 100. Unrated games are left out."
    end
    field :followers, UserType.connection_type, null: false, description: "Users that are following this user."
    field :following, UserType.connection_type, null: false, description: "Users that this user is following."
    field :favorited_games, GameType.connection_type, null: false, description: "Games that this user has favorited."
    field :activity, EventType.connection_type, null: false, description: "Activity Events that refer to this user."

    field :avatar_url, String, null: true, description: "URL for the user's avatar image. `null` means the user has the default avatar." do
      argument :size, Enums::UserAvatarSizeType, required: false, default_value: :small, description: "The size of the avatar image being requested."
    end

    field :is_followed, Boolean, null: true, resolver_method: :followed?, description: "Whether the current user is following this user. `null` if there is no logged-in user or the current user is querying on themselves."
    field :hide_days_played, Boolean, null: false, description: "Whether to hide the 'Days Played' value on the this user's profile."
    field :steam_profile_url, String, null: true, description: "URL of the Steam profile connected to this user's account. Only visible to the user themselves, `null` for anyone else or when no Steam account is connected."
    field :passkeys, [PasskeyType], null: true, description: "Passkeys this user can sign in with, newest first. Only visible to the user themselves, `null` for anyone else."

    def activity
      return [] unless user_visible?

      Views::NewEvent.recently_created
                     .includes(user: AttachmentPreloads::AVATAR)
                     .where(user_id: @object.id)
    end

    def avatar_url(size:)
      avatar = @object.sized_avatar(size)
      return if avatar.nil?

      avatar.url
    end

    # Preloading applied to the associations below once the viewer is allowed to
    # see them, so that a page of users doesn't load an avatar (or cover) one
    # record at a time.
    #
    # Followers and following are listed most recent follow first. The
    # connection's cursors are offsets, so without an ORDER BY a page could
    # repeat or skip users.
    FIELD_PRELOADS = {
      followers: ->(relation) { relation.with_attached_avatar.order(relationships: { id: :desc }) },
      following: ->(relation) { relation.with_attached_avatar.order(relationships: { id: :desc }) },
      favorited_games: ->(relation) { relation.with_attached_cover }
    }.freeze

    # Extremely cursed metaprogramming that protects private users from having
    # their details exposed if the UserPolicy wants to prevent it.
    def handler(field_name, fallback = nil)
      return fallback unless user_visible?

      value = @object.public_send(field_name)
      preload = FIELD_PRELOADS[field_name]
      preload ? preload.call(value) : value
    end

    # Define a method for each of these fields, to forward the correct info onto the handler method.
    # This overrides the default field accessors to make sure the viewer is actually supposed to
    # see this information.
    {
      bio: nil,
      followers: [],
      following: [],
      favorited_games: []
    }.each_pair do |meth_name, fallback|
      define_method(meth_name) do
        handler(meth_name, fallback)
      end
    end

    def game_purchases(sort_by: nil, **filters)
      return [] unless user_visible?

      purchases = filter_game_purchases(
        @object.game_purchases.includes(:platforms, :stores, game: AttachmentPreloads::COVER),
        **filters
      )

      purchases = batch_status_count(purchases, **filters.slice(:completion_status, :no_completion_status))

      # Order by ID when no sort was requested: cursor-based pagination walks
      # the relation by offset, so an unordered relation can repeat or skip
      # rows between pages.
      sort_by.nil? ? purchases.order(:id) : purchases.public_send(sort_by.to_sym)
    end

    # Calculated in SQL over the entire library rather than in the client over a
    # single page of game purchases, so that the numbers on a profile don't
    # change based on how many games the client has paged in.
    def library_statistics
      return EMPTY_LIBRARY_STATISTICS.merge(game_purchases: GamePurchase.none) unless user_visible?

      purchases = @object.game_purchases
      counts_by_status = purchases.group(:completion_status).count
      total_hours_played, average_rating = purchases.pick(
        Arel.sql('COALESCE(SUM(hours_played), 0)'),
        Arel.sql('AVG(rating)')
      )

      # Games with no completion status still count towards the library's size,
      # so total the counts before dropping the `nil` bucket.
      games_count = counts_by_status.values.sum
      status_counts = normalized_status_counts(counts_by_status)
      completed_count = GamePurchase::COMPLETED_STATUSES.sum { |status| status_counts.fetch(status.to_s, 0) }

      {
        games_count: games_count,
        total_hours_played: total_hours_played.to_f,
        completed_count: completed_count,
        completion_percentage: games_count.zero? ? 0 : (completed_count * 100.0 / games_count).round,
        average_rating: average_rating&.to_f&.round(1),
        status_counts: status_counts.map { |status, count| { status: status, count: count } },
        game_purchases: purchases
      }
    end

    def followed?
      return nil if @context[:current_user].nil? || @context[:current_user].id == @object.id

      @context[:current_user].following.exists?(id: @object.id)
    end

    # Which Steam account someone has connected isn't something other people
    # need to know, so only the user themselves can see it.
    def steam_profile_url
      return nil unless @context[:current_user]&.id == @object.id

      @object.external_account&.steam_profile_url
    end

    # Only the user themselves can see (and manage) their passkeys.
    def passkeys
      return nil unless @context[:current_user]&.id == @object.id

      @object.webauthn_credentials.order(created_at: :desc, id: :desc)
    end

    private

    def filter_game_purchases(purchases, completion_status: nil, no_completion_status: false, search: nil, platform_ids: nil, store_ids: nil, min_rating: nil, max_rating: nil)
      purchases = purchases.where(completion_status: completion_status) unless completion_status.nil?
      purchases = purchases.where(completion_status: nil) if no_completion_status
      purchases = purchases.with_game_name_matching(search) if search.present?
      purchases = purchases.on_any_platform(platform_ids) if platform_ids.present?
      purchases = purchases.from_any_store(store_ids) if store_ids.present?
      purchases = purchases.rated_between(min_rating, max_rating) unless min_rating.nil? && max_rating.nil?
      purchases
    end

    # A connection filtered to one completion status (or to no status) counts
    # its games together with the response's other such connections, see
    # `GamePurchaseStatusCounts`. Asking for both a status and no status
    # matches nothing, so that's left to count on its own.
    def batch_status_count(purchases, completion_status: nil, no_completion_status: false)
      return purchases if completion_status.nil? == !no_completion_status

      purchases.extending(GamePurchaseStatusCounts.extension(completion_status))
    end

    # What a library's statistics look like when the viewer isn't allowed to see
    # the library at all.
    EMPTY_LIBRARY_STATISTICS = {
      games_count: 0,
      total_hours_played: 0.0,
      completed_count: 0,
      completion_percentage: 0,
      average_rating: nil,
      status_counts: []
    }.freeze

    # Drop the games with no completion status and key the counts by the
    # status' string name. Grouping on an enum column gives back the enum's
    # names, but normalize integers too so that a change in that behaviour
    # can't silently zero out the completion stats.
    def normalized_status_counts(counts_by_status)
      counts_by_status.each_with_object({}) do |(status, count), counts|
        next if status.nil?

        name = status.is_a?(Integer) ? GamePurchase.completion_statuses.key(status) : status.to_s
        counts[name] = count
      end
    end

    def user_visible?
      # Short-circuit if the user has a public account and hasn't been banned,
      # to prevent instantiating a UserPolicy and all that. This condition must
      # stay identical to the first clause of UserPolicy#user_profile_is_visible?,
      # otherwise the fast path can expose profiles the policy would hide.
      return true if @object.public_account? && !@object.banned?

      UserPolicy.new(@context[:current_user], @object).show?
    end
  end
end
