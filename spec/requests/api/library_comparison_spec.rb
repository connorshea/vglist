# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Library comparison API", type: :request do
  let(:viewer) { create(:confirmed_user) }
  let(:token) { JwtService.encode(viewer) }
  let(:user_a) { create(:confirmed_user) }
  let(:user_b) { create(:confirmed_user) }

  let(:summary_query) do
    <<-GRAPHQL
      query($userASlug: String!, $userBSlug: String!) {
        libraryComparison(userASlug: $userASlug, userBSlug: $userBSlug) {
          userA { username }
          userB { username }
          inCommonCount
          onlyACount
          onlyBCount
          bothRatedCount
          averageRatingGap
        }
      }
    GRAPHQL
  end

  let(:in_common_query) do
    <<-GRAPHQL
      query($userASlug: String!, $userBSlug: String!, $sortBy: LibraryComparisonSort, $search: String, $bothRated: Boolean, $first: Int, $after: String) {
        libraryComparison(userASlug: $userASlug, userBSlug: $userBSlug) {
          inCommon(sortBy: $sortBy, search: $search, bothRated: $bothRated, first: $first, after: $after) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
              game { name }
              purchaseA { rating user { username } }
              purchaseB { rating user { username } }
              ratingDifference
            }
          }
        }
      }
    GRAPHQL
  end

  let(:only_query) do
    <<-GRAPHQL
      query($userASlug: String!, $userBSlug: String!, $search: String, $sortBy: GamePurchaseSort) {
        libraryComparison(userASlug: $userASlug, userBSlug: $userBSlug) {
          onlyA(search: $search, sortBy: $sortBy) { totalCount nodes { rating game { name } } }
          onlyB(search: $search, sortBy: $sortBy) { totalCount nodes { rating game { name } } }
        }
      }
    GRAPHQL
  end

  def compare(query, token: self.token, left: user_a, right: user_b, **variables)
    api_request(query, variables: { user_a_slug: left.slug, user_b_slug: right.slug, **variables }, token: token)
  end

  def own(user, name, rating: nil)
    game = Game.find_by(name: name) || create(:game, name: name)
    create(:game_purchase, user: user, game: game, rating: rating)
  end

  describe 'with two public libraries' do
    before(:each) do
      # Both own these four.
      own(user_a, 'Disco Elysium', rating: 97)
      own(user_b, 'Disco Elysium', rating: 78)
      own(user_a, 'Elden Ring', rating: 79)
      own(user_b, 'Elden Ring', rating: 98)
      own(user_a, 'Outer Wilds', rating: 96)
      own(user_b, 'Outer Wilds', rating: 96)
      own(user_a, 'Celeste', rating: 90)
      own(user_b, 'Celeste')
      # Only A.
      own(user_a, 'Portal 2', rating: 95)
      own(user_a, 'Tunic', rating: 90)
      # Only B.
      own(user_b, 'Bloodborne', rating: 97)
    end

    it 'returns the counts and the average gap across the games both rated' do
      result = compare(summary_query)

      expect(result.graphql_dig(:library_comparison)).to eq(
        {
          userA: { username: user_a.username },
          userB: { username: user_b.username },
          inCommonCount: 4,
          onlyACount: 2,
          onlyBCount: 1,
          bothRatedCount: 3,
          # (19 + 19 + 0) / 3
          averageRatingGap: 12.7
        }
      )
    end

    it 'sorts the games in common by the biggest disagreement by default, unrated last' do
      result = compare(in_common_query)
      nodes = result.graphql_dig(:library_comparison, :in_common, :nodes)

      # The 19-point gaps tie, so they're broken by name.
      expect(nodes.map { |node| node[:game][:name] }).to eq(['Disco Elysium', 'Elden Ring', 'Outer Wilds', 'Celeste'])
      expect(nodes.pluck(:ratingDifference)).to eq([19, -19, 0, nil])
    end

    it "includes both users' library entries for each game in common" do
      first_node = compare(in_common_query).graphql_dig(:library_comparison, :in_common, :nodes).first

      expect(first_node).to include(
        purchaseA: { rating: 97, user: { username: user_a.username } },
        purchaseB: { rating: 78, user: { username: user_b.username } }
      )
    end

    it 'sorts the games in common by either rating or by name' do
      names = ->(sort) { compare(in_common_query, sort_by: sort).graphql_dig(:library_comparison, :in_common, :nodes).map { |node| node[:game][:name] } }

      expect(names.call('USER_A_RATING')).to eq(['Disco Elysium', 'Outer Wilds', 'Celeste', 'Elden Ring'])
      expect(names.call('USER_B_RATING')).to eq(['Elden Ring', 'Outer Wilds', 'Disco Elysium', 'Celeste'])
      expect(names.call('GAME_NAME')).to eq(['Celeste', 'Disco Elysium', 'Elden Ring', 'Outer Wilds'])
    end

    it 'filters the games in common by name and to the ones both users rated' do
      searched = compare(in_common_query, search: 'elden').graphql_dig(:library_comparison, :in_common)
      rated = compare(in_common_query, both_rated: true).graphql_dig(:library_comparison, :in_common)

      expect(searched[:nodes].map { |node| node[:game][:name] }).to eq(['Elden Ring'])
      expect(rated[:totalCount]).to eq(3)
      expect(rated[:nodes].map { |node| node[:game][:name] }).not_to include('Celeste')
    end

    it 'pages through the games in common without repeating any' do
      first_page = compare(in_common_query, first: 2).graphql_dig(:library_comparison, :in_common)
      second_page = compare(in_common_query, first: 2, after: first_page[:pageInfo][:endCursor]).graphql_dig(:library_comparison, :in_common)

      expect(first_page[:pageInfo][:hasNextPage]).to be(true)
      names = (first_page[:nodes] + second_page[:nodes]).map { |node| node[:game][:name] }
      expect(names).to eq(['Disco Elysium', 'Elden Ring', 'Outer Wilds', 'Celeste'])
    end

    it "returns each user's games the other doesn't own, highest rated first" do
      result = compare(only_query).graphql_dig(:library_comparison)

      expect(result[:onlyA]).to eq({ totalCount: 2, nodes: [{ rating: 95, game: { name: 'Portal 2' } }, { rating: 90, game: { name: 'Tunic' } }] })
      expect(result[:onlyB]).to eq({ totalCount: 1, nodes: [{ rating: 97, game: { name: 'Bloodborne' } }] })
    end

    it "filters and sorts each user's games the other doesn't own" do
      result = compare(only_query, search: 'tun', sort_by: 'GAME_NAME').graphql_dig(:library_comparison)

      expect(result[:onlyA][:nodes]).to eq([{ rating: 90, game: { name: 'Tunic' } }])
      expect(result[:onlyB][:totalCount]).to eq(0)
    end

    it 'swaps the sides when the users are swapped' do
      result = compare(summary_query, left: user_b, right: user_a).graphql_dig(:library_comparison)

      expect(result).to include(onlyACount: 1, onlyBCount: 2, inCommonCount: 4)
    end

    it 'works without a signed-in user' do
      result = compare(summary_query, token: nil)

      expect(result.graphql_dig(:library_comparison, :in_common_count)).to eq(4)
    end

    it 'loads the second purchases in one query rather than one per row' do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('FROM "game_purchases"') }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { compare(in_common_query) }

      lookups = queries.select { |sql| sql.match?(/WHERE "game_purchases"\."id" (=|IN)/) }
      expect(lookups.size).to eq(1)
    end
  end

  it 'returns zeroes and no gap for two libraries with nothing in common' do
    own(user_a, 'Portal 2', rating: 95)

    result = compare(summary_query).graphql_dig(:library_comparison)

    expect(result).to include(inCommonCount: 0, onlyACount: 1, onlyBCount: 0, bothRatedCount: 0, averageRatingGap: nil)
  end

  it "returns null when a user doesn't exist" do
    result = api_request(summary_query, variables: { user_a_slug: user_a.slug, user_b_slug: 'nobody-here' }, token: token)

    expect(result.graphql_dig(:library_comparison)).to be_nil
    expect(result.to_h['errors']).to be_nil
  end

  describe 'with a private user' do
    let(:private_user) { create(:private_user) }

    it "refuses to compare a private user's library with someone else's" do
      result = compare(summary_query, left: user_a, right: private_user)

      expect(result.graphql_dig(:library_comparison)).to be_nil
      expect(api_result_errors(result)).to eq(["You aren't allowed to see #{private_user.username}'s library."])
    end

    it 'refuses whichever side the private user is on' do
      result = compare(summary_query, left: private_user, right: user_b)

      expect(api_result_errors(result)).to eq(["You aren't allowed to see #{private_user.username}'s library."])
    end

    it 'refuses without a signed-in user' do
      result = compare(summary_query, token: nil, left: user_a, right: private_user)

      expect(api_result_errors(result)).to eq(["You aren't allowed to see #{private_user.username}'s library."])
    end

    it 'lets the private user compare their own library' do
      result = compare(summary_query, token: JwtService.encode(private_user), left: private_user, right: user_b)

      expect(result.graphql_dig(:library_comparison, :user_a, :username)).to eq(private_user.username)
    end

    it 'lets someone the private user follows compare with them' do
      create(:relationship, follower: private_user, followed: viewer)

      result = compare(summary_query, left: viewer, right: private_user)

      expect(result.graphql_dig(:library_comparison, :user_b, :username)).to eq(private_user.username)
    end

    it 'lets an admin compare with them' do
      admin = create(:confirmed_admin)

      result = compare(summary_query, token: JwtService.encode(admin), left: user_a, right: private_user)

      expect(result.graphql_dig(:library_comparison, :user_b, :username)).to eq(private_user.username)
    end
  end

  it 'refuses to compare with a banned user' do
    banned_user = create(:banned_user)

    result = compare(summary_query, left: user_a, right: banned_user)

    expect(api_result_errors(result)).to eq(["You aren't allowed to see #{banned_user.username}'s library."])
  end
end
