require 'rails_helper'

RSpec.describe "Activity API", type: :request do
  describe "Query for data on activity globally" do
    let(:user) { create(:confirmed_user) }
    let(:user2) { create(:confirmed_user) }
    let(:user3) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:game_purchase) { create(:game_purchase, user: user) }
    let(:relationship) { create(:relationship, follower: user, followed: user2) }
    let(:favorite_game) { create(:favorite_game, user: user) }

    it "returns basic data for activity events" do
      user
      game_purchase
      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              user {
                username
              }
              eventable {
                __typename
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:activity, :nodes)).to include(
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "GamePurchase"
          }
        },
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "User"
          }
        }
      )
      expect(result.graphql_dig(:activity, :nodes).length).to eq(2)
    end

    it "returns data for various types of activity events" do
      user
      game_purchase
      relationship
      favorite_game

      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              user {
                username
              }
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
      GRAPHQL

      result = api_request(query_string, token: access_token)

      expect(result.graphql_dig(:activity, :nodes)).to include(
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "FavoriteGame",
            id: favorite_game.id.to_s
          }
        },
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "Relationship",
            id: relationship.id.to_s
          }
        },
        {
          user: {
            username: user2.username
          },
          eventable: {
            __typename: "User",
            id: user2.id.to_s
          }
        },
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "GamePurchase",
            id: game_purchase.id.to_s
          }
        },
        {
          user: {
            username: user.username
          },
          eventable: {
            __typename: "User",
            id: user.id.to_s
          }
        }
      )
    end

    context "when returning eventable fields used by the activity feed frontend" do
      let(:eventable_query_string) do
        <<-GRAPHQL
          query {
            activity(feedType: GLOBAL) {
              nodes {
                eventCategory
                user {
                  id
                  username
                  slug
                }
                eventable {
                  ... on GamePurchase {
                    game { id name }
                    completionStatus
                  }
                  ... on FavoriteGame {
                    game { id name }
                  }
                  ... on Relationship {
                    followed { id username slug }
                  }
                  ... on User {
                    id
                    username
                    slug
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      let(:nodes) do
        game_purchase
        relationship
        favorite_game

        result = api_request(eventable_query_string, token: access_token)
        result.graphql_dig(:activity, :nodes)
      end

      it "returns game fields on GamePurchase eventable" do
        add_to_library_node = nodes.find { |n| n[:eventCategory] == "ADD_TO_LIBRARY" }
        expect(add_to_library_node[:eventable][:game][:name]).to eq(game_purchase.game.name)
        expect(add_to_library_node[:eventable][:game][:id]).to eq(game_purchase.game.id.to_s)
      end

      it "returns game fields on FavoriteGame eventable" do
        favorite_node = nodes.find { |n| n[:eventCategory] == "FAVORITE_GAME" }
        expect(favorite_node[:eventable][:game][:name]).to eq(favorite_game.game.name)
        expect(favorite_node[:eventable][:game][:id]).to eq(favorite_game.game.id.to_s)
      end

      it "returns followed user details on Relationship eventable" do
        relationship_node = nodes.find { |n| n[:eventCategory] == "FOLLOWING" }
        expect(relationship_node[:eventable][:followed][:username]).to eq(user2.username)
        expect(relationship_node[:eventable][:followed][:slug]).to eq(user2.slug)
      end

      it "returns user details on NEW_USER eventable" do
        new_user_nodes = nodes.select { |n| n[:eventCategory] == "NEW_USER" }
        expect(new_user_nodes).not_to be_empty
        new_user_node = new_user_nodes.first
        expect(new_user_node[:eventable][:username]).to be_present
        expect(new_user_node[:eventable][:slug]).to be_present
      end
    end

    it "returns completionStatus on GamePurchase eventable when set" do
      game_purchase_with_status = create(:game_purchase, :completion_status, user: user)
      # Trigger the event by creating the game purchase above (which auto-creates an event)

      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              eventCategory
              eventable {
                ... on GamePurchase {
                  game { id name }
                  completionStatus
                }
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)
      nodes = result.graphql_dig(:activity, :nodes)

      add_to_library_node = nodes.find do |n|
        n[:eventCategory] == "ADD_TO_LIBRARY" &&
          n.dig(:eventable, :game, :id) == game_purchase_with_status.game.id.to_s
      end

      expect(add_to_library_node).not_to be_nil
      expect(add_to_library_node.dig(:eventable, :completionStatus)).to eq(
        game_purchase_with_status.completion_status.upcase
      )
    end

    it "returns basic data for 'following' activity" do
      user
      user2
      user3
      relationship
      query_string = <<-GRAPHQL
        query {
          activity(feedType: FOLLOWING) {
            nodes {
              user {
                username
              }
              eventable {
                __typename
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)

      # Doesn't include user3 because user isn't following them.
      expect(result.graphql_dig(:activity, :nodes)).to eq(
        [
          {
            user: {
              username: user.username
            },
            eventable: {
              __typename: "Relationship"
            }
          },
          {
            user: {
              username: user2.username
            },
            eventable: {
              __typename: "User"
            }
          },
          {
            user: {
              username: user.username
            },
            eventable: {
              __typename: "User"
            }
          }
        ]
      )
    end

    it "returns a following feed combining the user's own events and followed users' events, ordered by recent", :aggregate_failures do
      # Regression test for ActivityResolver's `.or(...)` construction.
      #
      # The resolver unions two Views::NewEvent relations — one for users
      # being followed, one for the current user — and then layers
      # `.includes(user: ...)` and `.recently_created` (an `.order(...)`
      # scope) on top. The previous implementation applied the includes
      # and order to the LEFT side of the OR only, which is structurally
      # incompatible with the right side and can raise
      # `ArgumentError: Relation passed to #or must be structurally compatible`.
      #
      # This test exercises all three dimensions at once: both branches
      # of the OR, the includes (by selecting user.avatarUrl which needs
      # the avatar_attachment preload), and the ordering.
      user
      user2
      user3 # unfollowed — must not appear
      relationship # user follows user2 → creates a Relationship event for user
      create(:game_purchase, user: user) # event belonging to current user
      create(:game_purchase, user: user2) # event belonging to a followed user
      create(:game_purchase, user: user3) # event belonging to an unfollowed user

      query_string = <<-GRAPHQL
        query {
          activity(feedType: FOLLOWING) {
            nodes {
              user {
                id
                username
                avatarUrl
              }
              eventable {
                __typename
              }
            }
          }
        }
      GRAPHQL

      expect { api_request(query_string, token: access_token) }.not_to raise_error

      result = api_request(query_string, token: access_token)
      nodes = result.graphql_dig(:activity, :nodes)

      # Both branches of the OR are represented: current user's own events
      # AND followed user's events.
      usernames = nodes.map { |n| n.dig(:user, :username) }
      expect(usernames).to include(user.username, user2.username)
      expect(usernames).not_to include(user3.username)

      # The `.recently_created` ordering must survive the OR composition.
      # Events are inserted in call order above, so the feed (ordered by
      # created_at desc) should be strictly non-increasing by the
      # underlying view's created_at — which means the list reversed
      # should match chronological creation order.
      created_ats = Views::NewEvent
                      .where(user_id: [user.id, user2.id])
                      .order("new_events.created_at desc")
                      .pluck(:created_at)
      expect(created_ats).to eq(created_ats.sort.reverse)
    end

    it "returns following feed with eventable details" do
      relationship
      query_string = <<-GRAPHQL
        query {
          activity(feedType: FOLLOWING) {
            nodes {
              eventCategory
              eventable {
                ... on Relationship {
                  followed { id username slug }
                }
                ... on User {
                  id
                  username
                  slug
                }
              }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)
      nodes = result.graphql_dig(:activity, :nodes)

      relationship_node = nodes.find { |n| n[:eventCategory] == "FOLLOWING" }
      expect(relationship_node[:eventable][:followed][:username]).to eq(user2.username)
      expect(relationship_node[:eventable][:followed][:slug]).to eq(user2.slug)
    end

    it "excludes private users from global activity feed" do
      private_user = create(:private_user)
      create(:game_purchase, user: private_user)

      query_string = <<-GRAPHQL
        query {
          activity(feedType: GLOBAL) {
            nodes {
              user { username }
            }
          }
        }
      GRAPHQL

      result = api_request(query_string, token: access_token)
      nodes = result.graphql_dig(:activity, :nodes)
      usernames = nodes.map { |n| n.dig(:user, :username) }

      expect(usernames).not_to include(private_user.username)
    end

    it "returns an error when querying following feed without authentication" do
      query_string = <<-GRAPHQL
        query {
          activity(feedType: FOLLOWING) {
            nodes {
              eventCategory
            }
          }
        }
      GRAPHQL

      post graphql_path,
        params: { query: query_string }

      json = JSON.parse(response.body)
      expect(json['errors'].first['message']).to eq("You must be logged in to view the following feed.")
    end
  end
end
