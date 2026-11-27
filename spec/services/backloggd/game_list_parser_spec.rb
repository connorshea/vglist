# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Backloggd::GameListParser, type: :service do
  let(:played_page) { file_fixture('backloggd/games_played_page_1.html').read }
  let(:last_page) { file_fixture('backloggd/games_backlog_last_page.html').read }

  describe '#entries' do
    it 'reads the slug, name and rating of each game' do
      entries = described_class.new(played_page, status: 'played').entries

      expect(entries.map(&:to_h)).to eq(
        [
          { slug: 'hollow-knight', name: 'Hollow Knight', rating: 90, status: 'played' },
          { slug: 'the-witcher-3-wild-hunt', name: 'The Witcher 3: Wild Hunt', rating: nil, status: 'played' },
          { slug: 'some-obscure-game', name: 'Some Obscure Game', rating: 50, status: 'played' }
        ]
      )
    end

    it 'falls back to the cover image for the name' do
      entries = described_class.new(last_page, status: 'backlog').entries

      expect(entries.map(&:to_h)).to eq([{ slug: 'elden-ring', name: 'Elden Ring', rating: nil, status: 'backlog' }])
    end

    it 'ignores links to games outside the games grid and duplicate cards' do
      html = <<~HTML
        <a href="/games/not-in-the-grid/">Popular</a>
        <div class="game-cover"><a href="/games/celeste/"></a><div class="game-text-centered">Celeste</div></div>
        <div class="game-cover"><a href="/games/celeste/"></a><div class="game-text-centered">Celeste</div></div>
      HTML

      expect(described_class.new(html).entries.map(&:slug)).to eq(['celeste'])
    end

    it 'raises on the bot check page' do
      parser = described_class.new(file_fixture('backloggd/anubis_challenge.html').read)

      expect(parser).to be_blocked
      expect { parser.entries }.to raise_error(Backloggd::GameListParser::BlockedError)
    end
  end

  describe '#next_page?' do
    it 'is true when there is a next page link' do
      expect(described_class.new(played_page)).to be_next_page
    end

    it 'is false on the last page' do
      expect(described_class.new(last_page)).not_to be_next_page
    end
  end
end
