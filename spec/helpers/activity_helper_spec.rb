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
    let(:favorite_game_event) { create(:favorite_game_event) }
    let(:new_user_event) { create(:new_user_event) }
    let(:following_event) { create(:following_event) }

    it 'returns true for a library event' do
      expect(helper.handleable_event?(game_purchase_library_event)).to be(true)
    end

    it 'returns false for an unplayed completion event' do
      expect(helper.handleable_event?(game_purchase_completion_event1)).to be(false)
    end

    it 'returns false for an in_progress completion event' do
      expect(helper.handleable_event?(game_purchase_completion_event2)).to be(false)
    end

    it 'returns true for a dropped completion event' do
      expect(helper.handleable_event?(game_purchase_completion_event3)).to be(true)
    end

    it 'returns true for a completed completion event' do
      expect(helper.handleable_event?(game_purchase_completion_event4)).to be(true)
    end

    it 'returns true for a fully completed completion event' do
      expect(helper.handleable_event?(game_purchase_completion_event5)).to be(true)
    end

    it 'returns false for a not_applicable completion event' do
      expect(helper.handleable_event?(game_purchase_completion_event6)).to be(false)
    end

    it 'returns true for a paused completion event' do
      expect(helper.handleable_event?(game_purchase_completion_event7)).to be(true)
    end

    it 'returns true for a favorite game event' do
      expect(helper.handleable_event?(favorite_game_event)).to be(true)
    end

    it 'returns true for a new user event' do
      expect(helper.handleable_event?(new_user_event)).to be(true)
    end

    it 'returns true for a following event' do
      expect(helper.handleable_event?(following_event)).to be(true)
    end
  end

  describe 'event text' do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game, user: user) }
    let(:game_purchase_library_event) { create(:game_purchase_library_event, user: user, eventable: game_purchase) }
    let(:game_purchase_completion_event_dropped) do
      create(
        :game_purchase_completion_event,
        eventable: game_purchase,
        user: user,
        differences: { completion_status: [nil, "dropped"] }
      )
    end
    let(:favorite_game) { create(:favorite_game, game: game, user: user) }
    let(:favorite_game_event) { create(:favorite_game_event, user: user, eventable: favorite_game) }
    let(:new_user_event) { create(:new_user_event, user: user, eventable: user) }
    let(:relationship) { create(:relationship, follower: user, followed: user2) }
    let(:following_event) { create(:following_event, user: user, eventable: relationship) }

    it 'returns the correct text for a game library event' do
      expect(
        strip_tags(helper.event_text(game_purchase_library_event))
      ).to eq "#{user.username} added #{game.name} to their library."
    end

    it 'returns the correct text for a completion status dropped event' do
      expect(
        strip_tags(helper.event_text(game_purchase_completion_event_dropped))
      ).to eq "#{user.username} dropped #{game.name}."
    end

    it 'returns the correct text for a favorite game event' do
      expect(
        strip_tags(helper.event_text(favorite_game_event))
      ).to eq "#{user.username} favorited #{game.name}."
    end

    it 'returns the correct text for a new user event' do
      expect(
        strip_tags(helper.event_text(new_user_event))
      ).to eq "#{user.username} created their account."
    end

    it 'returns the correct text for a following event' do
      expect(
        strip_tags(helper.event_text(following_event))
      ).to eq "#{user.username} started following #{user2.username}."
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
      expect(
        strip_tags(helper.completion_status_event_text(game_purchase_completion_event_dropped))
      ).to eq "#{user.username} dropped #{game.name}."
    end

    it 'returns the correct text for paused' do
      expect(
        strip_tags(helper.completion_status_event_text(game_purchase_completion_event_paused))
      ).to eq "#{user.username} paused #{game.name}."
    end

    it 'returns the correct text for completed' do
      expect(
        strip_tags(helper.completion_status_event_text(game_purchase_completion_event_completed))
      ).to eq "#{user.username} completed #{game.name}."
    end

    it 'returns the correct text for fully_completed' do
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
      expect(
        strip_tags(helper.add_to_library_event_text(game_purchase_library_event))
      ).to eq "#{user.username} added #{game.name} to their library."
    end
  end

  describe 'favorite game event text method' do
    let(:user) { create(:user) }
    let(:game) { create(:game) }
    let(:favorite_game) { create(:favorite_game, game: game, user: user) }
    let(:favorite_game_event) { create(:favorite_game_event, user: user, eventable: favorite_game) }

    it 'returns a sensible piece of text' do
      expect(
        strip_tags(helper.favorite_game_event_text(favorite_game_event))
      ).to eq "#{user.username} favorited #{game.name}."
    end
  end

  describe 'new user event text method' do
    let(:user) { create(:user) }
    let(:new_user_event) { create(:new_user_event, user: user, eventable: user) }

    it 'returns a sensible piece of text' do
      expect(
        strip_tags(helper.new_user_event_text(new_user_event))
      ).to eq "#{user.username} created their account."
    end
  end

  describe 'new follower event text method' do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:relationship) { create(:relationship, follower: user, followed: user2) }
    let(:following_event) { create(:following_event, user: user, eventable: relationship) }

    it 'returns a sensible piece of text' do
      expect(
        strip_tags(helper.following_event_text(following_event))
      ).to eq "#{user.username} started following #{user2.username}."
    end
  end
end
