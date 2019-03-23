require 'rails_helper'

RSpec.describe "Games", type: :request do
  describe "GET games_path" do
    it "returns http success" do
      get games_path
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

  describe "POST games_path" do
    let(:user) { create(:confirmed_user) }
    let(:game_attributes) { attributes_for(:game) }

    it "creates a new game" do
      sign_in(user)
      expect do
        post games_path, params: { game: game_attributes }
      end.to change(Game, :count).by(1)
    end

    it "fails to create a new game" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      game_attributes[:name] = long_name
      post games_path, params: { game: game_attributes }
      expect(response.body).to include('Unable to create game.')
    end
  end

  describe "PUT game_path" do
    let(:user) { create(:confirmed_user) }
    let!(:game) { create(:game) }
    let(:game_attributes) { attributes_for(:game) }

    it "updates game description" do
      sign_in(user)
      game_attributes[:description] = "Description goes here"
      put game_path(id: game.id), params: { game: game_attributes }
      expect(game.reload.description).to eql("Description goes here")
    end

    it "fails to update game" do
      sign_in(user)
      long_name = Faker::Lorem.characters(125)
      game_attributes[:name] = long_name
      put game_path(id: game.id), params: { game: game_attributes }
      expect(response.body).to include('Unable to update game.')
    end
  end

  describe "DELETE game_path" do
    let(:user) { create(:confirmed_user) }
    let!(:game) { create(:game) }

    it "deletes a game" do
      sign_in(user)
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
        delete remove_game_from_library_game_path(game.id),
          params: { id: game.id }
      end.to change(user_with_game.game_purchases.all, :count).by(-1)
    end

    it "doesn't remove a game from the user's library if none exist" do
      sign_in(user)
      delete remove_game_from_library_game_path(game.id),
        params: { id: game.id }
      expect(response).to redirect_to(game_url(game))
      # Need to follow redirect for the flash message to show up.
      follow_redirect!
      expect(response.body).to include("Unable to remove game from your library.")
    end
  end

  describe "DELETE remove_cover_game_path" do
    let(:user) { create(:confirmed_user) }
    let(:game_with_cover) { create(:game_with_cover) }

    it "removes the cover from a game" do
      sign_in(user)
      delete remove_cover_game_path(game_with_cover.id),
        params: { id: game_with_cover.id }
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
        post favorite_game_path(game.id, format: :json),
          params: { id: game.id }
      end.to change(user.favorites, :count).by(1)
    end
  end

  describe "DELETE favorite_game_path" do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }

    it 'decreases the favorite count by 1' do
      create(:favorite, user: user, favoritable: game)

      sign_in(user)
      expect do
        delete unfavorite_game_path(game.id, format: :json),
          params: { id: game.id }
      end.to change(user.favorites, :count).by(-1)
    end
  end
end
