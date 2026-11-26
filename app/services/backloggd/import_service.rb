# frozen_string_literal: true

module Backloggd
  # Adds the games from a Backloggd games list to a user's vglist library.
  #
  # Games are matched on IGDB ID: Backloggd's game URLs use IGDB's slugs, and
  # vglist stores the same slug (from Wikidata) in games.igdb_id.
  #
  # Games already in the library are left alone, except that a completion
  # status or rating the user hasn't set on vglist is filled in from
  # Backloggd.
  class ImportService
    # vglist has no wishlist, so wishlisted games aren't imported.
    COMPLETION_STATUSES = {
      'playing' => :in_progress,
      'played' => :completed,
      'backlog' => :unplayed
    }.freeze

    # When a game shows up under more than one filter, the most specific
    # status wins.
    STATUS_PRIORITY = ['playing', 'played', 'backlog', nil].freeze

    Unmatched = Struct.new(:name, :slug)

    Result = Struct.new(:created, :updated, :unmatched, :skipped_wishlist_count) do
      def added_games
        Game.joins(:game_purchases).merge(created)
      end

      def updated_games
        Game.joins(:game_purchases).merge(updated)
      end
    end

    attr_reader :user, :entries

    # entries: Backloggd::GameListParser::Entry objects.
    def initialize(user:, entries:)
      @user = user
      @entries = entries
    end

    def call
      wishlist, entries = deduplicated_entries.partition { |entry| entry.status == 'wishlist' }

      game_ids_by_slug = Game.where(igdb_id: entries.map(&:slug)).pluck(:igdb_id, :id).to_h
      purchases_by_game_id = GamePurchase.where(user: user, game_id: game_ids_by_slug.values).index_by(&:game_id)

      created_ids = []
      updated_ids = []
      unmatched = []

      entries.each do |entry|
        game_id = game_ids_by_slug[entry.slug]
        if game_id.nil?
          unmatched << Unmatched.new(entry.name, entry.slug)
          next
        end

        attributes = attributes_for(entry)
        purchase = purchases_by_game_id[game_id]

        if purchase.nil?
          created = GamePurchase.create(user: user, game_id: game_id, **attributes)
          created_ids << created.id if created.persisted?
        else
          # Only fill in what the user hasn't set on vglist.
          blanks = attributes.select { |key, _| purchase[key].nil? }
          updated_ids << purchase.id if blanks.any? && purchase.update(blanks)
        end
      end

      log_unmatched(unmatched)

      Result.new(
        created: GamePurchase.where(id: created_ids),
        updated: GamePurchase.where(id: updated_ids),
        unmatched: unmatched.sort_by { |game| game.name.downcase },
        skipped_wishlist_count: wishlist.size
      )
    end

    private

    # Keep one entry per game. A game on the wishlist and in another list is
    # treated as being in the other list.
    def deduplicated_entries
      entries.group_by(&:slug).map do |_slug, duplicates|
        duplicates.min_by { |entry| STATUS_PRIORITY.index(entry.status) || STATUS_PRIORITY.size }
      end
    end

    def attributes_for(entry)
      {
        completion_status: COMPLETION_STATUSES[entry.status],
        rating: entry.rating
      }.compact
    end

    # Record the games we couldn't match, so the most common ones can be added
    # to vglist (or given IGDB IDs) later.
    def log_unmatched(unmatched)
      unmatched.each do |game|
        UnmatchedGame.create_with(name: game.name.truncate(120)).find_or_create_by(
          user_id: user.id,
          external_service_id: game.slug,
          external_service_name: 'Backloggd'
        )
      end
    end
  end
end
