# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users API", type: :request do
  describe "Query for data on users" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:access_token) { JwtService.encode(user) }
    let(:user_with_avatar) { create(:confirmed_user_with_avatar) }
    let(:access_token_for_user_with_avatar) { JwtService.encode(user_with_avatar) }
    let(:private_user) { create(:private_user) }
    let(:banned_user) { create(:banned_user) }
    let(:admin) { create(:confirmed_admin) }
    let(:admin_access_token) { JwtService.encode(admin) }

    it "returns basic data for user" do
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            role
            privacy
            avatarUrl
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: user.id }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user.id.to_s,
          username: user.username,
          role: user.role.upcase,
          privacy: user.privacy.upcase,
          avatarUrl: nil
        }
      )
    end

    it "returns basic data for user when searching by username" do
      query_string = <<-GRAPHQL
        query($username: String!) {
          user(username: $username) {
            id
            username
            role
            privacy
            avatarUrl
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { username: user.username }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user.id.to_s,
          username: user.username,
          role: user.role.upcase,
          privacy: user.privacy.upcase,
          avatarUrl: nil
        }
      )
    end

    it "returns basic data for user when searching by slug" do
      query_string = <<-GRAPHQL
        query($slug: String!) {
          user(slug: $slug) {
            id
            username
            role
            privacy
            avatarUrl
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { slug: user.slug }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user.id.to_s,
          username: user.username,
          role: user.role.upcase,
          privacy: user.privacy.upcase,
          avatarUrl: nil
        }
      )
    end

    it "returns an error if the query uses both an id and username" do
      query_string = <<-GRAPHQL
        query($id: ID!, $username: String!) {
          user(id: $id, username: $username) {
            id
            username
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: user.id, username: user.username }, token: access_token)

      expect(result.graphql_dig(:user)).to be_nil
      expect(result.to_h["errors"].first['message']).to eq('Cannot provide more than one argument to user at a time.')
    end

    it "returns avatar for user" do
      sign_in(user_with_avatar)
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            avatarUrl
          }
        }
      GRAPHQL

      avatar_variant = user_with_avatar.avatar.variant(:small).processed

      result = api_request(query_string, variables: { id: user_with_avatar.id }, token: access_token_for_user_with_avatar)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user_with_avatar.id.to_s,
          username: user_with_avatar.username,
          avatarUrl: variant_url(avatar_variant)
        }
      )
    end

    it "returns a private user's library to a user they follow" do
      create(:relationship, follower: private_user, followed: user)
      game_purchase = create(:game_purchase, user: private_user)

      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            gamePurchases {
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: private_user.id }, token: access_token)

      expect(result.to_h['errors']).to be_nil
      expect(result.graphql_dig(:user, :game_purchases, :nodes)).to eq([{ id: game_purchase.id.to_s }])
    end

    it "returns only public data for private user" do
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            bio
            gamePurchases {
              nodes {
                id
              }
            }
            activity {
              nodes {
                id
              }
            }
            followers {
              nodes {
                id
              }
            }
            following {
              nodes {
                id
              }
            }
            favoritedGames {
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: private_user.id }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: private_user.id.to_s,
          username: private_user.username,
          bio: nil,
          gamePurchases: { nodes: [] },
          activity: { nodes: [] },
          followers: { nodes: [] },
          following: { nodes: [] },
          favoritedGames: { nodes: [] }
        }
      )
    end

    it "returns only public data for banned user" do
      create(:game_purchase, user: banned_user)
      create(:favorite_game, user: banned_user)

      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            banned
            bio
            gamePurchases {
              nodes {
                id
              }
            }
            activity {
              nodes {
                id
              }
            }
            followers {
              nodes {
                id
              }
            }
            following {
              nodes {
                id
              }
            }
            favoritedGames {
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: banned_user.id }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: banned_user.id.to_s,
          username: banned_user.username,
          banned: true,
          bio: nil,
          gamePurchases: { nodes: [] },
          activity: { nodes: [] },
          followers: { nodes: [] },
          following: { nodes: [] },
          favoritedGames: { nodes: [] }
        }
      )
    end

    it "returns a banned user's data to an admin" do
      create(:game_purchase, user: banned_user)

      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            bio
            gamePurchases {
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: banned_user.id }, token: admin_access_token)

      expect(result.graphql_dig(:user, :bio)).to eq(banned_user.bio)
      expect(result.graphql_dig(:user, :gamePurchases, :nodes).length).to eq(1)
    end

    it "returns activity for user" do
      query_string = <<-GRAPHQL
        query($id: ID!) {
          user(id: $id) {
            id
            username
            activity {
              nodes {
                id
                eventable {
                  __typename
                  ... on User {
                    id
                  }
                  ... on GamePurchase {
                    id
                  }
                  ... on Relationship {
                    id
                  }
                  ... on FavoriteGame {
                    id
                  }
                }
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { id: user.id }, token: access_token)

      expect(result.graphql_dig(:user)).to eq(
        {
          id: user.id.to_s,
          username: user.username,
          activity: {
            nodes: [
              {
                id: user.new_events.first.id,
                eventable: {
                  id: user.id.to_s,
                  __typename: "User"
                }
              }
            ]
          }
        }
      )
    end

    it "pages through followers and following, most recent follow first" do
      followers = create_list(:confirmed_user, 3)
      followers.each { |follower| create(:relationship, follower: follower, followed: user) }
      followed = create_list(:confirmed_user, 3)
      followed.each { |other| create(:relationship, follower: user, followed: other) }
      ids = ->(users) { users.map { |u| { id: u.id.to_s } } }
      # The SPA builds the cursor for `?page=N` itself, as the offset encoded
      # in unpadded URL-safe Base64 (see frontend/src/utils/pagination.ts).
      offset_cursor = Base64.urlsafe_encode64("2", padding: false)

      query_string = <<-GRAPHQL
        query($id: ID!, $after: String) {
          user(id: $id) {
            followers(first: 2, after: $after) {
              nodes { id }
              pageInfo { hasNextPage endCursor }
            }
            following(first: 2, after: $after) {
              nodes { id }
              pageInfo { hasNextPage endCursor }
            }
          }
        }
      GRAPHQL

      first_page = api_request(query_string, variables: { id: user.id }, token: access_token)
      expect(first_page.graphql_dig(:user)).to eq(
        {
          followers: { nodes: ids.call(followers.last(2).reverse), pageInfo: { hasNextPage: true, endCursor: offset_cursor } },
          following: { nodes: ids.call(followed.last(2).reverse), pageInfo: { hasNextPage: true, endCursor: offset_cursor } }
        }
      )

      second_page = api_request(query_string, variables: { id: user.id, after: offset_cursor }, token: access_token)
      expect(second_page.graphql_dig(:user)).to eq(
        {
          followers: { nodes: ids.call([followers.first]), pageInfo: { hasNextPage: false, endCursor: Base64.urlsafe_encode64("3", padding: false) } },
          following: { nodes: ids.call([followed.first]), pageInfo: { hasNextPage: false, endCursor: Base64.urlsafe_encode64("3", padding: false) } }
        }
      )
    end

    it "returns data for users when listing" do
      user
      user2
      query_string = <<-GRAPHQL
        query {
          users {
            nodes {
              id
              username
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:users, :nodes)).to include(
        {
          id: user.id.to_s,
          username: user.username
        },
        {
          id: user2.id.to_s,
          username: user2.username
        }
      )
    end

    it "returns data for a user when searching" do
      user
      query_string = <<-GRAPHQL
        query($query: String!) {
          userSearch(query: $query) {
            nodes {
              id
              username
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, variables: { query: user.username }, token: access_token)

      expect(result.graphql_dig(:user_search, :nodes)).to eq(
        [{
          id: user.id.to_s,
          username: user.username
        }]
      )
    end

    context 'with favoritedGames' do
      let!(:favorite_game) { create(:favorite_game, user: user) }

      it "returns data for current user's favorite games when requesting favoritedGames" do
        query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              favoritedGames {
                nodes {
                  id
                  name
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user, :favorited_games, :nodes)).to include(
          {
            id: favorite_game.game.id.to_s,
            name: favorite_game.game.name
          }
        )
      end
    end

    context 'with isFollowed field' do
      let(:relationship) { create(:relationship, follower: user, followed: user2) }
      let(:query_string) do
        <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              isFollowed
            }
          }
        GRAPHQL
      end

      it "returns true for current user that follows this user" do
        relationship
        result = api_request(query_string, variables: { id: user2.id }, token: access_token)
        expect(result.graphql_dig(:user)).to eq({ isFollowed: true })
      end

      it "returns false for current user that doesn't follow this user" do
        result = api_request(query_string, variables: { id: user2.id }, token: access_token)
        expect(result.graphql_dig(:user)).to eq({ isFollowed: false })
      end

      it "returns null for current user that is looking at themselves" do
        result = api_request(query_string, variables: { id: user.id }, token: access_token)
        expect(result.graphql_dig(:user)).to eq({ isFollowed: nil })
      end
    end

    context 'when requesting game purchases with associations' do
      let!(:game_purchase) { create(:game_purchase_with_everything, user: user) }

      it "returns game purchase data with platforms and stores", :aggregate_failures do
        query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              gamePurchases {
                nodes {
                  id
                  game { id name }
                  platforms { nodes { id name } }
                  stores { nodes { id name } }
                  completionStatus
                  rating
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: user.id }, token: access_token)
        purchase_node = result.graphql_dig(:user, :game_purchases, :nodes).first

        expect(purchase_node[:id]).to eq(game_purchase.id.to_s)
        expect(purchase_node[:game][:name]).to eq(game_purchase.game.name)
        expect(purchase_node[:platforms][:nodes].first[:name]).to eq(game_purchase.platforms.first.name)
        expect(purchase_node[:stores][:nodes].first[:name]).to eq(game_purchase.stores.first.name)
      end
    end

    context 'when filtering and sorting game purchases' do
      let!(:completed_purchase) { create(:game_purchase, user: user, game: create(:game, name: 'Bastion'), completion_status: :completed, rating: 90, hours_played: 12.0) }
      let!(:unplayed_purchase) { create(:game_purchase, user: user, game: create(:game, name: 'Celeste'), completion_status: :unplayed) }
      let!(:in_progress_purchase) { create(:game_purchase, user: user, game: create(:game, name: 'Alien Isolation'), completion_status: :in_progress, rating: 70, hours_played: 30.5) }

      let(:query_string) do
        <<-GRAPHQL
          query($id: ID!, $completionStatus: GamePurchaseCompletionStatus, $noCompletionStatus: Boolean, $search: String, $sortBy: GamePurchaseSort) {
            user(id: $id) {
              gamePurchases(completionStatus: $completionStatus, noCompletionStatus: $noCompletionStatus, search: $search, sortBy: $sortBy) {
                totalCount
                nodes {
                  id
                }
              }
            }
          }
        GRAPHQL
      end

      def purchase_ids(**variables)
        result = api_request(query_string, variables: { id: user.id, **variables }, token: access_token)
        result.graphql_dig(:user, :game_purchases, :nodes).pluck(:id)
      end

      it "filters by completion status" do
        expect(purchase_ids(completion_status: 'COMPLETED')).to eq([completed_purchase.id.to_s])
      end

      it "filters to the games with no completion status" do
        no_status_purchase = create(:game_purchase, user: user, completion_status: nil)

        expect(purchase_ids(no_completion_status: true)).to eq([no_status_purchase.id.to_s])
        expect(purchase_ids(no_completion_status: false).length).to eq(4)
      end

      it "filters by a case-insensitive substring of the game's name" do
        expect(purchase_ids(search: 'lie')).to eq([in_progress_purchase.id.to_s])
      end

      context 'when asking for one shelf per completion status' do
        let(:shelves_query) do
          <<-GRAPHQL
            query($id: ID!, $search: String) {
              user(id: $id) {
                completed: gamePurchases(completionStatus: COMPLETED, search: $search) { totalCount }
                unplayed: gamePurchases(completionStatus: UNPLAYED, search: $search) { totalCount }
                inProgress: gamePurchases(completionStatus: IN_PROGRESS, search: $search) { totalCount }
                dropped: gamePurchases(completionStatus: DROPPED, search: $search) { totalCount }
                noStatus: gamePurchases(noCompletionStatus: true, search: $search) { totalCount }
                everything: gamePurchases(search: $search) { totalCount }
                nothing: gamePurchases(completionStatus: COMPLETED, noCompletionStatus: true, search: $search) { totalCount }
              }
            }
          GRAPHQL
        end

        def shelf_counts(**variables)
          result = api_request(shelves_query, variables: { id: user.id, **variables }, token: access_token)
          result.graphql_dig(:user).transform_values { |shelf| shelf[:totalCount] }
        end

        before(:each) do
          create(:game_purchase, user: user, game: create(:game, name: 'Celeste 64'), completion_status: :unplayed)
          create(:game_purchase, user: user, game: create(:game, name: 'Hades'), completion_status: nil)
          # Another user's library doesn't count.
          create(:game_purchase, completion_status: :unplayed)
        end

        it "counts each shelf" do
          expect(shelf_counts).to eq(
            completed: 1, unplayed: 2, inProgress: 1, dropped: 0, noStatus: 1, everything: 5, nothing: 0
          )
        end

        it "applies the shared filters to every shelf's count" do
          expect(shelf_counts(search: 'cele')).to eq(
            completed: 0, unplayed: 2, inProgress: 0, dropped: 0, noStatus: 0, everything: 2, nothing: 0
          )
        end

        it "counts the status shelves in one query" do
          count_queries = []
          callback = ->(*, payload) { count_queries << payload[:sql] if payload[:sql].include?('COUNT(') }
          ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { shelf_counts }

          # One grouped count for the five status shelves, plus one each for
          # the unfiltered and contradictory connections.
          expect(count_queries.length).to eq(3)
          expect(count_queries).to include(a_string_including('GROUP BY "game_purchases"."completion_status"'))
        end
      end

      it "treats the search string as a literal, not as a LIKE pattern" do
        expect(purchase_ids(search: '%')).to eq([])
      end

      it "sorts by the game's name" do
        expect(purchase_ids(sort_by: 'GAME_NAME')).to eq(
          [in_progress_purchase.id.to_s, completed_purchase.id.to_s, unplayed_purchase.id.to_s]
        )
      end

      it "sorts by rating, with unrated games last" do
        expect(purchase_ids(sort_by: 'HIGHEST_RATING')).to eq(
          [completed_purchase.id.to_s, in_progress_purchase.id.to_s, unplayed_purchase.id.to_s]
        )
      end

      it "sorts by hours played, with games that have no hours logged last" do
        expect(purchase_ids(sort_by: 'MOST_HOURS_PLAYED')).to eq(
          [in_progress_purchase.id.to_s, completed_purchase.id.to_s, unplayed_purchase.id.to_s]
        )
      end

      it "counts the whole filtered library, not just the requested page" do
        paged_query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              gamePurchases(first: 1) {
                totalCount
                nodes {
                  id
                }
              }
            }
          }
        GRAPHQL

        result = api_request(paged_query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user, :game_purchases, :total_count)).to eq(3)
        expect(result.graphql_dig(:user, :game_purchases, :nodes).length).to eq(1)
      end
    end

    context 'when filtering game purchases by platform, store and rating' do
      let(:windows) { create(:platform) }
      let(:switch) { create(:platform) }
      let(:steam) { create(:store) }
      let(:gog) { create(:store) }

      let!(:steam_windows_purchase) { create(:game_purchase, user: user, platforms: [windows], stores: [steam], rating: 95) }
      let!(:switch_purchase) { create(:game_purchase, user: user, platforms: [switch], rating: 60) }
      let!(:gog_windows_purchase) { create(:game_purchase, user: user, platforms: [windows], stores: [gog]) }
      let!(:both_platforms_purchase) { create(:game_purchase, user: user, platforms: [windows, switch], rating: 80) }

      let(:query_string) do
        <<-GRAPHQL
          query($id: ID!, $platformIds: [ID!], $storeIds: [ID!], $minRating: Int, $maxRating: Int) {
            user(id: $id) {
              gamePurchases(platformIds: $platformIds, storeIds: $storeIds, minRating: $minRating, maxRating: $maxRating) {
                totalCount
                nodes {
                  id
                }
              }
            }
          }
        GRAPHQL
      end

      def purchase_ids(**variables)
        result = api_request(query_string, variables: { id: user.id, **variables }, token: access_token)
        result.graphql_dig(:user, :game_purchases, :nodes).pluck(:id)
      end

      it "returns the games owned on any of the given platforms, each once" do
        expect(purchase_ids(platform_ids: [windows.id, switch.id])).to contain_exactly(
          steam_windows_purchase.id.to_s,
          switch_purchase.id.to_s,
          gog_windows_purchase.id.to_s,
          both_platforms_purchase.id.to_s
        )
        expect(purchase_ids(platform_ids: [switch.id])).to contain_exactly(
          switch_purchase.id.to_s,
          both_platforms_purchase.id.to_s
        )
      end

      it "returns the games owned from any of the given stores" do
        expect(purchase_ids(store_ids: [steam.id, gog.id])).to contain_exactly(
          steam_windows_purchase.id.to_s,
          gog_windows_purchase.id.to_s
        )
      end

      it "returns the rated games within an inclusive rating range" do
        expect(purchase_ids(min_rating: 80)).to contain_exactly(
          steam_windows_purchase.id.to_s,
          both_platforms_purchase.id.to_s
        )
        expect(purchase_ids(min_rating: 60, max_rating: 80)).to contain_exactly(
          switch_purchase.id.to_s,
          both_platforms_purchase.id.to_s
        )
      end

      it "combines the filters" do
        expect(purchase_ids(platform_ids: [windows.id], min_rating: 90)).to eq([steam_windows_purchase.id.to_s])
      end

      it "ignores empty lists" do
        expect(purchase_ids(platform_ids: [], store_ids: []).length).to eq(4)
      end
    end

    describe 'libraryStatistics' do
      let(:query_string) do
        <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              libraryStatistics {
                gamesCount
                totalHoursPlayed
                completedCount
                completionPercentage
                averageRating
                statusCounts {
                  status
                  count
                }
              }
            }
          }
        GRAPHQL
      end

      it "returns zeroed statistics for an empty library" do
        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user, :library_statistics)).to eq(
          {
            gamesCount: 0,
            totalHoursPlayed: 0.0,
            completedCount: 0,
            completionPercentage: 0,
            averageRating: nil,
            statusCounts: []
          }
        )
      end

      it "aggregates over the whole library, not just the page of game purchases the client requested" do
        create(:game_purchase, user: user, completion_status: :completed, rating: 100, hours_played: 10.0)
        create(:game_purchase, user: user, completion_status: :fully_completed, rating: 80, hours_played: 5.5)
        create(:game_purchase, user: user, completion_status: :in_progress, hours_played: 4.5)
        # No completion status, so it counts towards the library's size but not
        # towards any of the status counts.
        create(:game_purchase, user: user, completion_status: nil)

        result = api_request(query_string, variables: { id: user.id }, token: access_token)
        statistics = result.graphql_dig(:user, :library_statistics)

        expect(statistics).to include(
          gamesCount: 4,
          totalHoursPlayed: 20.0,
          completedCount: 2,
          # 2 of 4 games completed.
          completionPercentage: 50,
          # Only the two rated games are averaged.
          averageRating: 90.0
        )
        expect(statistics[:statusCounts]).to contain_exactly(
          { status: 'COMPLETED', count: 1 },
          { status: 'FULLY_COMPLETED', count: 1 },
          { status: 'IN_PROGRESS', count: 1 }
        )
      end

      it "returns zeroed statistics for a private user's library" do
        create(:game_purchase, user: private_user, completion_status: :completed, rating: 100, hours_played: 10.0)

        result = api_request(query_string, variables: { id: private_user.id }, token: access_token)

        expect(result.graphql_dig(:user, :library_statistics)).to eq(
          {
            gamesCount: 0,
            totalHoursPlayed: 0.0,
            completedCount: 0,
            completionPercentage: 0,
            averageRating: nil,
            statusCounts: []
          }
        )
      end

      it "returns a private user's library statistics to that user" do
        create(:game_purchase, user: private_user, completion_status: :completed, rating: 100, hours_played: 10.0)
        private_user_token = JwtService.encode(private_user)

        result = api_request(query_string, variables: { id: private_user.id }, token: private_user_token)

        expect(result.graphql_dig(:user, :library_statistics)).to include(
          gamesCount: 1,
          totalHoursPlayed: 10.0,
          completedCount: 1,
          completionPercentage: 100,
          averageRating: 100.0
        )
      end

      context 'with platform and store counts' do
        let(:counts_query_string) do
          <<-GRAPHQL
            query($id: ID!) {
              user(id: $id) {
                libraryStatistics {
                  platformCounts {
                    platform { id name }
                    count
                  }
                  storeCounts {
                    store { id name }
                    count
                  }
                }
              }
            }
          GRAPHQL
        end

        it "counts the games on each platform and from each store, most-owned first" do
          windows = create(:platform, name: 'Windows')
          switch = create(:platform, name: 'Nintendo Switch')
          steam = create(:store, name: 'Steam')
          create(:game_purchase, user: user, platforms: [windows, switch], stores: [steam])
          create(:game_purchase, user: user, platforms: [windows], stores: [steam])
          create(:game_purchase, user: user, platforms: [windows])
          # Someone else's library doesn't count.
          create(:game_purchase, platforms: [switch], stores: [steam])

          result = api_request(counts_query_string, variables: { id: user.id }, token: access_token)
          statistics = result.graphql_dig(:user, :library_statistics)

          expect(statistics[:platformCounts]).to eq(
            [
              { platform: { id: windows.id.to_s, name: 'Windows' }, count: 3 },
              { platform: { id: switch.id.to_s, name: 'Nintendo Switch' }, count: 1 }
            ]
          )
          expect(statistics[:storeCounts]).to eq(
            [{ store: { id: steam.id.to_s, name: 'Steam' }, count: 2 }]
          )
        end

        it "returns no counts for a private user's library" do
          create(:game_purchase, user: private_user, platforms: [create(:platform)], stores: [create(:store)])

          result = api_request(counts_query_string, variables: { id: private_user.id }, token: access_token)

          expect(result.graphql_dig(:user, :library_statistics)).to eq({ platformCounts: [], storeCounts: [] })
        end
      end
    end

    context 'with currentUser' do
      it "returns data for current user when requesting currentUser" do
        user
        query_string = <<-GRAPHQL
          query {
            currentUser {
              id
              username
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:current_user)).to eq(
          {
            id: user.id.to_s,
            username: user.username
          }
        )
      end
    end

    describe 'email privacy' do
      # Email is sensitive and must never be exposed via the GraphQL API under
      # any circumstances. See the NOTE at the top of UserType.
      it "does not define an email field on the User type" do
        user_type = VideoGameListSchema.types['User']
        expect(user_type).not_to be_nil
        expect(user_type.fields.keys).not_to include('email')
      end

      it "returns an error when querying email on a user directly" do
        query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              id
              email
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user)).to be_nil
        expect(api_result_errors(result)).to include(a_string_matching(/email/i))
      end

      it "returns an error when querying email via currentUser" do
        query_string = <<-GRAPHQL
          query {
            currentUser {
              id
              email
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:current_user)).to be_nil
        expect(api_result_errors(result)).to include(a_string_matching(/email/i))
      end

      it "returns an error when querying email via the users list" do
        query_string = <<-GRAPHQL
          query {
            users {
              nodes {
                id
                email
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, token: access_token)

        expect(result.graphql_dig(:users)).to be_nil
        expect(api_result_errors(result)).to include(a_string_matching(/email/i))
      end

      it "returns an error when querying email via userSearch" do
        query_string = <<-GRAPHQL
          query($query: String!) {
            userSearch(query: $query) {
              nodes {
                id
                email
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { query: user.username }, token: access_token)

        expect(result.graphql_dig(:user_search)).to be_nil
        expect(api_result_errors(result)).to include(a_string_matching(/email/i))
      end

      it "does not expose email on nested user types (e.g. activity, followers)" do
        # UserType is reused everywhere a user is returned (events, game
        # purchases, relationships, favorites, etc.) so the schema-level check
        # above covers all of them, but verify a couple of nested paths too as
        # belt-and-suspenders against someone adding a parallel User-like type
        # in the future.
        query_string = <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              id
              followers {
                nodes {
                  id
                  email
                }
              }
            }
          }
        GRAPHQL

        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user)).to be_nil
        expect(api_result_errors(result)).to include(a_string_matching(/email/i))
      end
    end

    context 'when sorting users' do
      # Need to do some fancy stuff here otherwise the order of the results is
      # non-deterministic, which causes flaky failures. We make sure that the
      # users each have a different number of followers and a different number
      # of owned games.
      let(:user) do
        create(:user_with_game_purchase) do |current_user|
          create(:relationship, follower: user2, followed: current_user)
          create(:relationship, follower: user3, followed: current_user)
        end
      end
      let(:user2) do
        create(:user) do |current_user|
          create(:relationship, follower: user3, followed: current_user)
        end
      end
      let(:user3) do
        create(:user_with_game_purchase) do |current_user|
          create_list(:game_purchase, 3, user: current_user)
        end
      end

      # Test each sort order and make sure it matches the corresponding sort
      # method. We test the sort scopes individually in method specs, so we
      # should be able to rely on those tests for testing the specific order.
      [:most_games, :most_followers].each do |sort_order|
        it "returns data in expected order for #{sort_order}" do
          query_string = <<~GRAPHQL_WITH_INTERP
            query {
              users(sortBy: #{sort_order.upcase}) {
                nodes {
                  id
                  username
                }
              }
            }
          GRAPHQL_WITH_INTERP

          result = api_request(query_string, token: access_token)
          # This is a bit of a hack to get the users in the same format as
          # they're returned by GraphQL (hashes with only the specific
          # requested keys, with IDs being strings).
          expected_users = User.public_send(sort_order).select(:id, :username).map(&:as_json).map(&:symbolize_keys).map do |user|
            user[:id] = user[:id].to_s
            user
          end

          expect(result.graphql_dig(:users, :nodes)).to eq(expected_users)
        end

        it "returns totalCount when sorting by #{sort_order}" do
          query_string = <<~GRAPHQL_WITH_INTERP
            query {
              users(sortBy: #{sort_order.upcase}) {
                totalCount
              }
            }
          GRAPHQL_WITH_INTERP

          result = api_request(query_string, token: access_token)

          expect(result.graphql_dig(:users, :total_count)).to eq(User.where(banned: false).count)
        end
      end
    end

    context 'when preloading avatars for a list of users' do
      # Authenticating lazily would create the user inside the measured block.
      before(:each) { access_token }

      let(:users_query) do
        <<-GRAPHQL
          query {
            users {
              nodes {
                id
                username
                avatarUrl(size: SMALL)
              }
            }
          }
        GRAPHQL
      end

      # The first request for an avatar generates its variant, which writes
      # records and is unrelated to preloading, so warm those up and measure
      # the second request.
      def warm_then_count_queries
        api_request(users_query, token: access_token)
        query_count { api_request(users_query, token: access_token) }
      end

      it "runs no more queries as the list grows" do
        create_list(:confirmed_user_with_avatar, 2)
        baseline = warm_then_count_queries

        create_list(:confirmed_user_with_avatar, 3)

        expect(warm_then_count_queries).to eq(baseline)
      end
    end

    describe "steamProfileUrl" do
      let(:query_string) do
        <<-GRAPHQL
          query($id: ID!) {
            user(id: $id) {
              steamProfileUrl
            }
          }
        GRAPHQL
      end

      it "returns the connected Steam profile to the user themselves" do
        create(:external_account, user: user, steam_profile_url: 'https://steamcommunity.com/id/connor/')

        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user, :steamProfileUrl)).to eq('https://steamcommunity.com/id/connor/')
      end

      it "returns nil when the user has no Steam account connected" do
        result = api_request(query_string, variables: { id: user.id }, token: access_token)

        expect(result.graphql_dig(:user, :steamProfileUrl)).to be_nil
      end

      it "returns nil to other users" do
        create(:external_account, user: user2)

        result = api_request(query_string, variables: { id: user2.id }, token: access_token)

        expect(result.graphql_dig(:user, :steamProfileUrl)).to be_nil
      end
    end
  end
end
