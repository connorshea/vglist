# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin games export", type: :request do
  let(:path) { '/api/admin/games_export' }

  def auth_headers(user)
    { 'Authorization' => "Bearer #{JwtService.encode(user)}" }
  end

  context 'when signed in as an admin' do
    let(:admin) { create(:confirmed_admin) }

    it 'downloads a dated JSON attachment' do
      get path, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(response.headers['Content-Disposition'])
        .to match(/attachment; filename="vglist-games-\d{4}-\d{2}-\d{2}\.json"/)
    end

    it 'includes an export timestamp' do
      get path, headers: auth_headers(admin)

      expect(JSON.parse(response.body)['exported_at']).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)
    end

    it "exports every game's name, ID, Steam app IDs, and Wikidata ID" do
      game = create(:game, name: 'Half-Life 2', wikidata_id: 193_581)
      create(:steam_app_id, game: game, app_id: 220)
      create(:steam_app_id, game: game, app_id: 218)
      bare_game = create(:game, name: 'No IDs')

      get path, headers: auth_headers(admin)

      expect(JSON.parse(response.body)['games']).to eq(
        [
          { 'id' => game.id, 'name' => 'Half-Life 2', 'steam_app_ids' => [218, 220], 'wikidata_id' => 193_581 },
          { 'id' => bare_game.id, 'name' => 'No IDs', 'steam_app_ids' => [], 'wikidata_id' => nil }
        ]
      )
    end

    it 'returns an empty list when there are no games' do
      get path, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['games']).to eq([])
    end
  end

  context 'when signed in as a moderator' do
    it 'is forbidden' do
      get path, headers: auth_headers(create(:confirmed_moderator))

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when signed in as a member' do
    it 'is forbidden and does not leak game data' do
      create(:game, name: 'Secret')

      get path, headers: auth_headers(create(:confirmed_user))

      expect(response).to have_http_status(:forbidden)
      expect(response.body).not_to include('Secret')
    end
  end

  context 'when signed in as a banned admin' do
    it 'is forbidden' do
      admin = create(:confirmed_admin, banned: true)

      get path, headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when not signed in' do
    it 'is forbidden' do
      get path

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'with a revoked token' do
    it 'is forbidden' do
      admin = create(:confirmed_admin)
      headers = auth_headers(admin)
      JwtService.revoke_all!(admin)

      get path, headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
