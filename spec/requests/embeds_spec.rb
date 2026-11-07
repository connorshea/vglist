# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Game link-preview embeds", type: :request do
  let(:discordbot) { 'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)' }

  def discord_payload
    script = Nokogiri::HTML(response.body).at_css('script#discord\:component-embed')
    script && JSON.parse(script.text)
  end

  def meta(property)
    Nokogiri::HTML(response.body).at_css("meta[property='#{property}']")&.[]('content')
  end

  describe "GET /embeds/games/:id" do
    context 'with a game that has a cover' do
      let(:game) { create(:game, :cover, name: 'Portal & "Friends"', release_date: Date.new(2007, 10, 10)) }

      it 'returns Open Graph tags and a Discord component embed', :aggregate_failures do
        get "/embeds/games/#{game.id}", headers: { 'User-Agent' => discordbot }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq('text/html')
        expect(response.headers['Cache-Control']).to include('public', 'max-age=3600')
        expect(meta('og:title')).to eq('Portal & "Friends"')
        expect(meta('og:url')).to eq("http://localhost:5173/games/#{game.id}")
        expect(meta('og:description')).to eq('Released October 10, 2007')
        expect(meta('og:image')).to start_with('http://www.example.com/')
        expect(discord_payload['component']['type']).to eq(17)
        expect(response.body).to include('<meta http-equiv="refresh"')
      end
    end

    context 'with a game without a cover' do
      let(:game) { create(:game) }

      it 'omits the image tags but still has an embed', :aggregate_failures do
        get "/embeds/games/#{game.id}"

        expect(response).to have_http_status(:ok)
        expect(meta('og:image')).to be_nil
        expect(meta('og:title')).to eq(game.name)
        expect(discord_payload['component']['type']).to eq(17)
      end
    end

    it 'returns 404 with no embed for a missing game', :aggregate_failures do
      get '/embeds/games/0', headers: { 'User-Agent' => discordbot }

      expect(response).to have_http_status(:not_found)
      expect(response.body).to be_empty
    end

    it 'does not route non-numeric ids' do
      get '/embeds/games/abc'

      expect(response).not_to have_http_status(:ok)
    end
  end
end
