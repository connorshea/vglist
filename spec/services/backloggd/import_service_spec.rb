# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Backloggd::ImportService, type: :service do
  let(:user) { create(:user) }
  let!(:hollow_knight) { create(:game, igdb_id: 'hollow-knight') }
  let!(:witcher) { create(:game, igdb_id: 'the-witcher-3-wild-hunt') }

  def entry(slug, status: 'played', rating: nil, name: slug.titleize)
    Backloggd::GameListParser::Entry.new(slug: slug, name: name, rating: rating, status: status)
  end

  def import(*entries)
    described_class.new(user: user, entries: entries).call
  end

  it 'adds matched games with their status and rating' do
    result = import(entry('hollow-knight', rating: 90), entry('the-witcher-3-wild-hunt', status: 'playing'))

    expect(result.added_games).to contain_exactly(hollow_knight, witcher)
    expect(user.game_purchases.find_by(game: hollow_knight)).to have_attributes(completion_status: 'completed', rating: 90)
    expect(user.game_purchases.find_by(game: witcher)).to have_attributes(completion_status: 'in_progress', rating: nil)
  end

  it 'maps the backlog to unplayed' do
    import(entry('hollow-knight', status: 'backlog'))

    expect(user.game_purchases.sole.completion_status).to eq('unplayed')
  end

  it 'skips wishlisted games' do
    create(:game, igdb_id: 'elden-ring')
    result = import(entry('elden-ring', status: 'wishlist'))

    expect(result.created).to be_empty
    expect(result.skipped_wishlist_count).to eq(1)
  end

  it 'prefers the playing status when a game is in several lists' do
    import(entry('hollow-knight', status: 'wishlist'), entry('hollow-knight', status: 'backlog'), entry('hollow-knight', status: 'playing'))

    expect(user.game_purchases.sole.completion_status).to eq('in_progress')
  end

  it 'only fills in what is blank for games already in the library' do
    create(:game_purchase, user: user, game: hollow_knight, completion_status: :dropped, rating: nil)
    create(:game_purchase, user: user, game: witcher, completion_status: :paused, rating: 40)

    result = import(entry('hollow-knight', rating: 90), entry('the-witcher-3-wild-hunt', rating: 100))

    expect(result.updated_games).to contain_exactly(hollow_knight)
    expect(user.game_purchases.find_by(game: hollow_knight)).to have_attributes(completion_status: 'dropped', rating: 90)
    expect(user.game_purchases.find_by(game: witcher)).to have_attributes(completion_status: 'paused', rating: 40)
  end

  it 'reports and logs games it cannot match' do
    result = nil

    expect { result = import(entry('some-obscure-game', name: 'Some Obscure Game')) }
      .to change(UnmatchedGame.where(external_service_name: 'Backloggd'), :count).by(1)
    expect(result.unmatched.map(&:to_h)).to eq([{ name: 'Some Obscure Game', slug: 'some-obscure-game' }])

    expect { import(entry('some-obscure-game')) }.not_to change(UnmatchedGame, :count)
  end
end
