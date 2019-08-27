# typed: false
require 'rails_helper'

RSpec.describe ActivityHelper, type: :helper do
  describe 'handleable event' do
    let(:game_purchase_library_event) { create(:game_purchase_library_event) }
    let(:game_purchase_completion_event1) { create(:game_purchase_completion_event, differences: { completion_status: [nil, "unplayed"] }) }
    let(:game_purchase_completion_event2) { create(:game_purchase_completion_event, differences: { completion_status: [nil, "in_progress"] }) }
    let(:game_purchase_completion_event3) { create(:game_purchase_completion_event, differences: { completion_status: [nil, "dropped"] }) }
    let(:game_purchase_completion_event4) { create(:game_purchase_completion_event, differences: { completion_status: [nil, "completed"] }) }
    let(:game_purchase_completion_event5) { create(:game_purchase_completion_event, differences: { completion_status: [nil, "fully_completed"] }) }
    let(:game_purchase_completion_event6) { create(:game_purchase_completion_event, differences: { completion_status: [nil, "not_applicable"] }) }
    let(:game_purchase_completion_event7) { create(:game_purchase_completion_event, differences: { completion_status: [nil, "paused"] }) }

    it 'returns true for a library event' do
      game_purchase_library_event
      expect(helper.handleable_event?(game_purchase_library_event)).to be(true)
    end

    it 'returns false for an unplayed completion event' do
      game_purchase_completion_event1
      expect(helper.handleable_event?(game_purchase_completion_event1)).to be(false)
    end

    it 'returns false for an in_progress completion event' do
      game_purchase_completion_event2
      expect(helper.handleable_event?(game_purchase_completion_event2)).to be(false)
    end

    it 'returns true for a dropped completion event' do
      game_purchase_completion_event3
      expect(helper.handleable_event?(game_purchase_completion_event3)).to be(true)
    end

    it 'returns true for a completed completion event' do
      game_purchase_completion_event4
      expect(helper.handleable_event?(game_purchase_completion_event4)).to be(true)
    end

    it 'returns true for a fully completed completion event' do
      game_purchase_completion_event5
      expect(helper.handleable_event?(game_purchase_completion_event5)).to be(true)
    end

    it 'returns false for a not_applicable completion event' do
      game_purchase_completion_event6
      expect(helper.handleable_event?(game_purchase_completion_event6)).to be(false)
    end

    it 'returns true for a paused completion event' do
      game_purchase_completion_event7
      expect(helper.handleable_event?(game_purchase_completion_event7)).to be(true)
    end
  end

  describe 'change completion status event text' do
    let(:user) { create(:user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game, user: user) }
    let(:game_purchase_completion_event_dropped) do
      create(
        :game_purchase_completion_event,
        eventable: game_purchase,
        user: user,
        differences: { completion_status: [nil, "dropped"] }
      )
    end
    let(:game_purchase_completion_event_paused) do
      create(
        :game_purchase_completion_event,
        eventable: game_purchase,
        user: user,
        differences: { completion_status: [nil, "paused"] }
      )
    end
    let(:game_purchase_completion_event_completed) do
      create(
        :game_purchase_completion_event,
        eventable: game_purchase,
        user: user,
        differences: { completion_status: [nil, "completed"] }
      )
    end
    let(:game_purchase_completion_event_fully_completed) do
      create(
        :game_purchase_completion_event,
        eventable: game_purchase,
        user: user,
        differences: { completion_status: [nil, "fully_completed"] }
      )
    end

    it 'returns the correct text for dropped' do
      game_purchase_completion_event_dropped
      expect(
        strip_tags(helper.completion_status_event_text(game_purchase_completion_event_dropped))
      ).to eq "#{user.username} dropped #{game.name}."
    end

    it 'returns the correct text for paused' do
      game_purchase_completion_event_paused
      expect(
        strip_tags(helper.completion_status_event_text(game_purchase_completion_event_paused))
      ).to eq "#{user.username} paused #{game.name}."
    end

    it 'returns the correct text for completed' do
      game_purchase_completion_event_completed
      expect(
        strip_tags(helper.completion_status_event_text(game_purchase_completion_event_completed))
      ).to eq "#{user.username} completed #{game.name}."
    end

    it 'returns the correct text for fully_completed' do
      game_purchase_completion_event_fully_completed
      expect(
        strip_tags(helper.completion_status_event_text(game_purchase_completion_event_fully_completed))
      ).to eq "#{user.username} 100% completed #{game.name}."
    end
  end

  describe 'add to library event text method' do
    let(:user) { create(:user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game, user: user) }
    let(:game_purchase_library_event) { create(:game_purchase_library_event, user: user, eventable: game_purchase) }

    it 'returns a sensible piece of text' do
      game_purchase_library_event
      expect(
        strip_tags(helper.add_to_library_event_text(game_purchase_library_event))
      ).to eq "#{user.username} added #{game.name} to their library."
    end
  end
end
