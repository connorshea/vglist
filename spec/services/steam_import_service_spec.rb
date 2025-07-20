require 'rails_helper'

RSpec.describe SteamImportService, type: :service do
  let(:response) do
    {
      'response': {
        'game_count': 1,
        'games': [
          {
            'appid': 10,
            'name': "Counter-Strike",
            'playtime_forever': 455,
            'img_icon_url': "6b0312cda02f5f777efa2f3318c307ff9acafbb5",
            'playtime_windows_forever': 2,
            'playtime_mac_forever': 0,
            'playtime_linux_forever': 0,
            'playtime_deck_forever': 0,
            'rtime_last_played': 1_695_786_469,
            'content_descriptorids': [
              2,
              5
            ],
            'playtime_disconnected': 0
          }
        ]
      }
    }
  end

  # Ensure we don't use a real Steam Web API Key in these tests.
  around(:each) do |example|
    with_environment('STEAM_WEB_API_KEY' => 'foo') do
      example.run
    end
  end

  before(:each) do
    stub_request(:get, /api.steampowered.com/).to_return(
      status: 200,
      body: response.to_json,
      headers: {}
    )
  end

  describe "importing games from Steam" do
    let!(:game_a) { create(:game) }
    let!(:steam_app_id) { create(:steam_app_id, app_id: 10, game: game_a) } # rubocop:disable RSpec/LetSetup
    let(:user) { create(:user, :external_account) }

    it 'works with update_hours false' do
      expect { SteamImportService.new(user: user, update_hours: false).call }.to change(GamePurchase, :count).by(1)
    end

    it 'works with update_hours true' do
      expect { SteamImportService.new(user: user, update_hours: true).call }.to change(GamePurchase, :count).by(1)
    end
  end
end
