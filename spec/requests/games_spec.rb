require 'rails_helper'

RSpec.describe "Games", type: :request do
  describe "GET games_path" do
    # rubocop:disable RSpec/LetSetup
    let!(:games) { create_list(:game, 5) }
    # rubocop:enable RSpec/LetSetup
    let(:platform) { create(:platform) }
    let(:game_with_platform) { create(:game, platforms: [platform]) }

    it "returns http success" do
      get games_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success when ordered by newest" do
      get games_path(order_by: :newest)
      expect(response).to have_http_status(:success)
    end

    it "returns http success when ordered by oldest" do
      get games_path(order_by: :oldest)
      expect(response).to have_http_status(:success)
    end

    it "returns http success when ordered by recently updated" do
      get games_path(order_by: :recently_updated)
      expect(response).to have_http_status(:success)
    end

    it "returns http success when ordered by least recently updated" do
      get games_path(order_by: :least_recently_updated)
      expect(response).to have_http_status(:success)
    end

    it "returns http success when ordered by most favorites" do
      get games_path(order_by: :most_favorites)
      expect(response).to have_http_status(:success)
    end

    it "returns http success when ordered by most owners" do
      get games_path(order_by: :most_owners)
      expect(response).to have_http_status(:success)
    end

    it "returns http success when ordered by recently released" do
      get games_path(order_by: :recently_released)
      expect(response).to have_http_status(:success)
    end

    it "returns http success when filtered by platform" do
      game_with_platform
      get games_path(filter_platform: platform.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET game_path" do
    let(:game) { create(:game) }
    let(:game_with_everything) { create(:game_with_everything) }

    it "returns http success" do
      get game_path(id: game.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for a game with everything" do
      get game_path(id: game_with_everything.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET activity_game_path" do
    let(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, game: game, user: user) }
    let(:favorite_game) { create(:favorite_game, game: game, user: user) }

    it "returns http success" do
      get activity_game_path(id: game.id)
      expect(response).to have_http_status(:success)
    end

    it "returns http success when there are events for the game" do
      game_purchase
      favorite_game
      get activity_game_path(id: game.id)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST games_path" do
    let(:user) { create(:confirmed_moderator) }
    let(:game_attributes) { attributes_for(:game) }

    it "creates a new game" do
      sign_in(user)
      expect do
        post games_path, params: { game: game_attributes }
      end.to change(Game, :count).by(1)
    end

    it "fails to create a new game" do
      sign_in(user)
      long_name = Faker::Lorem.characters(number: 125)
      game_attributes[:name] = long_name
      post games_path, params: { game: game_attributes }
      expect(response.body).to include('Unable to create game.')
    end
  end

  describe "PUT game_path" do
    let(:user) { create(:confirmed_moderator) }
    let!(:game) { create(:game) }
    let(:game_attributes) { attributes_for(:game) }

    it "updates game Wikidata ID" do
      sign_in(user)
      game_attributes[:wikidata_id] = 12_345
      put game_path(id: game.id), params: { game: game_attributes }
      expect(game.reload.wikidata_id).to be(12_345)
    end

    it "fails to update game" do
      sign_in(user)
      long_name = Faker::Lorem.characters(number: 125)
      game_attributes[:name] = long_name
      put game_path(id: game.id), params: { game: game_attributes }
      expect(response.body).to include('Unable to update game.')
    end
  end

  describe "DELETE game_path" do
    let(:user) { create(:confirmed_user) }
    let(:moderator) { create(:confirmed_moderator) }
    let!(:game) { create(:game) }

    it "does not delete the game" do
      sign_in(user)
      expect do
        delete game_path(id: game.id)
      end.not_to change(Game, :count)
    end

    it "deletes the game" do
      sign_in(moderator)
      expect do
        delete game_path(id: game.id)
      end.to change(Game, :count).by(-1)
    end
  end

  describe "GET search_games_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }

    it "returns the given game" do
      sign_in(user)
      get search_games_path(query: game.name, format: :json)
      expect(JSON.parse(response.body).first.to_json).to eq(game.to_json)
    end

    it "returns no game" do
      sign_in(user)
      get search_games_path(query: SecureRandom.alphanumeric(8), format: :json)
      expect(response.body).to eq("[]")
    end

    it "returns no game when no query is given" do
      sign_in(user)
      get search_games_path(format: :json)
      expect(response.body).to eq("[]")
    end
  end

  describe "POST add_game_to_library_game_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:user_with_game) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: user_with_game, game: game) }

    it "adds a game to the user's library" do
      sign_in(user)
      expect do
        post add_game_to_library_game_path(game.id),
          params: { game_purchase: { user_id: user.id, game_id: game.id } }
      end.to change(user.game_purchases.all, :count).by(1)
    end

    it "doesn't add a duplicate game to the user's library" do
      sign_in(user_with_game)
      game_purchase
      post add_game_to_library_game_path(game.id),
        params: { game_purchase: { user_id: user_with_game.id, game_id: game.id } }
      expect(response).to redirect_to(game_url(game))
      follow_redirect!
      expect(response.body).to include("Unable to add game to your library.")
    end
  end

  describe "POST add_to_wikidata_blocklist_game_path" do
    let(:admin) { create(:confirmed_admin) }
    let(:game) { create(:game, :wikidata_id) }

    it "creates a new blocklist entry" do
      sign_in(admin)
      expect do
        post add_to_wikidata_blocklist_game_path(game)
      end.to change(WikidataBlocklist, :count).by(1)
    end

    it "removes the wikidata_id for a game" do
      sign_in(admin)
      post add_to_wikidata_blocklist_game_path(game)
      expect(response).to redirect_to(game_path(game))
      expect(game.reload.wikidata_id).to eq(nil)
    end
  end

  describe "DELETE remove_game_from_library_game_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:user_with_game) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: user_with_game, game: game) }

    it "removes a game from the user's library" do
      sign_in(user_with_game)
      # Load the game purchase.
      game_purchase
      expect do
        delete remove_game_from_library_game_path(game.id)
      end.to change(user_with_game.game_purchases.all, :count).by(-1)
    end

    it "doesn't remove a game from the user's library if none exist" do
      sign_in(user)
      delete remove_game_from_library_game_path(game.id)
      expect(response).to redirect_to(game_url(game))
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Unable to remove game from your library.")
    end
  end

  describe "DELETE remove_cover_game_path" do
    let(:moderator) { create(:confirmed_moderator) }
    let(:game_with_cover) { create(:game_with_cover) }

    it "removes the cover from a game" do
      sign_in(moderator)
      delete remove_cover_game_path(game_with_cover.id)
      expect(response).to redirect_to(game_url(game_with_cover))
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Cover successfully removed from #{game_with_cover.name}.")
    end
  end

  describe "POST favorite_game_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }

    it "favorites a game successfully" do
      sign_in(user)
      expect do
        post favorite_game_path(game.id, format: :json)
      end.to change(user.favorite_games, :count).by(1)
    end

    it "does not favorite a game that's already been favorited" do
      create(:favorite_game, user: user, game: game)
      sign_in(user)
      expect do
        post favorite_game_path(game.id, format: :json)
      end.not_to change(user.favorite_games, :count)
    end
  end

  describe "DELETE favorite_game_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }

    it 'decreases the favorite game count by 1' do
      create(:favorite_game, user: user, game: game)

      sign_in(user)
      expect do
        delete unfavorite_game_path(game.id, format: :json)
      end.to change(user.favorite_games, :count).by(-1)
    end

    it "does not change anything if a game hasn't been favorited" do
      sign_in(user)
      expect do
        delete unfavorite_game_path(game.id, format: :json)
      end.not_to change(user.favorite_games, :count)
    end
  end

  describe "GET favorited_game_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }

    it 'returns true when the game has been favorited' do
      create(:favorite_game, user: user, game: game)
      sign_in(user)

      get favorited_game_path(game.id, format: :json)
      expect(response.body).to eq("true")
    end

    it 'returns false when the game has not been favorited' do
      sign_in(user)

      get favorited_game_path(game.id, format: :json)
      expect(response.body).to eq("false")
    end
  end

  describe "POST merge_game_path" do
    let(:admin) { create(:confirmed_admin) }
    let!(:game_a) { create(:game) }
    let!(:game_b) { create(:game) }

    it "merges a game successfully" do
      sign_in(admin)
      expect do
        post merge_game_path(game_a.id, game_b_id: game_b.id, format: :json)
      end.to change(Game, :count).by(-1)
    end

    it "merges a game successfully and redirects" do
      sign_in(admin)
      post merge_game_path(game_a.id, game_b_id: game_b.id, format: :json)
      expect(response).to redirect_to(game_url(game_a))
      follow_redirect!
      expect(response.body).to include("#{game_b.name} successfully merged into #{game_a.name}.")
    end

    it "fails when attempting to merge a game with itself" do
      sign_in(admin)
      post merge_game_path(game_a.id, game_b_id: game_a.id, format: :json)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
