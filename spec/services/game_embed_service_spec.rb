# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GameEmbedService do
  subject(:embed) { described_class.new(game) }

  # Cover URLs from the Disk service (used in tests) need a host to build on.
  around(:each) do |example|
    ActiveStorage::Current.set(url_options: { protocol: 'http://', host: 'www.example.com', port: 80 }) do
      example.run
    end
  end

  def payload
    JSON.parse(embed.discord_payload_json)
  end

  def all_components(component = payload['component'])
    children = Array(component['components']) + [component['accessory']].compact
    [component] + children.flat_map { |child| all_components(child) }
  end

  def text_content
    all_components.filter_map { |c| c['content'] }.join("\n")
  end

  def button_labels
    all_components.select { |c| c['type'] == 2 }.pluck('label')
  end

  describe '#discord_payload_json' do
    context 'with a fully populated game' do
      let(:series) { create(:series, name: 'Half-Life') }
      let(:game) do
        create(
          :game,
          :cover,
          name: 'Half-Life 2',
          series: series,
          release_date: Date.new(2004, 11, 16),
          pcgamingwiki_id: 'Half-Life_2',
          gog_id: 'half_life_2'
        )
      end

      before(:each) do
        game.developers << create(:company, name: 'Valve')
        game.platforms << create(:platform, name: 'Windows')
        game.genres << create(:genre, name: 'First-person shooter')
        create(:steam_app_id, game: game, app_id: 220)
        create_list(:game_purchase, 2, game: game)
        # Set after the purchases, whose callbacks recalculate the average.
        game.update_column(:avg_rating, 92.4) # rubocop:disable Rails/SkipsModelValidations
      end

      it 'is a single container with the expected parts', :aggregate_failures do
        expect(payload['component']['type']).to eq(17)
        expect(text_content).to include('## [Half-Life 2](http://localhost:5173/games/')
        expect(text_content).to include('Valve · Released November 16, 2004')
        expect(text_content).to include('**Platforms:** Windows')
        expect(text_content).to include('**Genres:** First\\-person shooter')
        expect(text_content).to include('**Series:** Half\\-Life')
        expect(text_content).to include('-# Owned by 2 vglist users · Avg. rating 92')
        expect(button_labels).to eq(['View on vglist', 'Steam', 'PCGamingWiki', 'GOG'])
      end

      it 'uses the cover as the section thumbnail', :aggregate_failures do
        section = payload['component']['components'].first
        expect(section['type']).to eq(9)
        expect(section['accessory']['type']).to eq(11)
        expect(section['accessory']['media']['url']).to eq(embed.image_url)
        expect(embed.image_url).to be_present
      end

      it 'only uses allowed fields on link buttons' do
        buttons = all_components.select { |c| c['type'] == 2 }
        expect(buttons).to all(satisfy { |b| b['style'] == 5 && (b.keys - %w[type style label url]).empty? })
      end
    end

    context 'with punctuation in the name' do
      let(:game) { create(:game, name: 'The Legend of Zelda: Ocarina of Time (3D) - *Remix* [v1.0]') }

      it 'only escapes link-label syntax in the title' do
        expect(text_content).to include(
          '## [The Legend of Zelda: Ocarina of Time (3D) - \\*Remix\\* \\[v1.0\\]](http://localhost:5173/games/'
        )
      end
    end

    context 'with a game without a cover or metadata' do
      let(:game) { create(:game, name: 'Obscure Game') }

      it 'uses a plain text display instead of a section', :aggregate_failures do
        components = payload['component']['components']
        expect(components.pluck('type')).to eq([10, 1])
        expect(all_components.pluck('type')).not_to include(9, 11)
        expect(button_labels).to eq(['View on vglist'])
      end
    end

    context 'with very long metadata' do
      let(:long_name) { "#{'*_[Long] Game_* ' * 6}End" }
      let(:game) do
        create(
          :game,
          :cover,
          name: long_name,
          series: create(:series, name: 'S' * 120),
          pcgamingwiki_id: 'P' * 300,
          epic_games_store_id: 'e' * 300,
          gog_id: 'g' * 300,
          avg_rating: 50
        )
      end

      before(:each) do
        30.times do |i|
          game.platforms << create(:platform, name: "Platform with a very long name number #{i}")
          game.genres << create(:genre, name: "Genre with a very long name number #{i}")
          game.developers << create(:company, name: "Developer <with> a long name & number #{i}")
        end
        create(:steam_app_id, game: game)
        create(:game_purchase, game: game)
      end

      it 'stays under the byte limit by dropping detail', :aggregate_failures do
        expect(embed.discord_payload_json.bytesize).to be <= GameEmbedService::MAX_PAYLOAD_BYTES
        expect(embed.discord_payload.to_json.bytesize).to be > GameEmbedService::MAX_PAYLOAD_BYTES
        expect(button_labels).to include('View on vglist')
      end
    end

    it 'escapes characters that could close the script element' do
      game = create(:game, name: '</script><script>alert(1)</script>')
      json = described_class.new(game).discord_payload_json
      expect(json).not_to include('<', '>')
    end
  end

  describe '#description' do
    it 'falls back to a generic description' do
      game = create(:game, name: 'Bare Game')
      expect(described_class.new(game).description).to eq('Bare Game on vglist')
    end

    it 'says "Releases" for unreleased games' do
      game = create(:game, release_date: 1.year.from_now.to_date)
      expect(described_class.new(game).description).to start_with('Releases ')
    end
  end
end
