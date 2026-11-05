require 'rails_helper'

RSpec.describe Views::NewEvent, type: :model do
  subject(:event) { create(:event) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(event).to be_valid
    end

    it { should validate_presence_of(:event_category) }

    it 'has an event category enum' do
      expect(Views::NewEvent.find(event.id)).to define_enum_for(:event_category)
        .with_values(
          [
            :add_to_library,
            :change_completion_status,
            :favorite_game,
            :new_user,
            :following
          ]
        )
    end
  end

  describe "Associations" do
    it { should belong_to(:eventable) }
    it { should belong_to(:user) }
  end

  describe "Scopes" do
    describe ".recently_created" do
      let(:user) { create(:confirmed_user) }

      it "returns events in descending created_at order" do
        game_purchase1 = create(:game_purchase, user: user)
        game_purchase2 = create(:game_purchase, user: user)

        events = Views::NewEvent.recently_created.where(event_category: :add_to_library)
        expect(events.first.created_at).to be >= events.last.created_at
        expect(events.map(&:eventable_id)).to eq([game_purchase2.id, game_purchase1.id])
      end

      it "works when joined with users table without ambiguous column error" do
        create(:game_purchase, user: user)

        expect do
          Views::NewEvent.recently_created.includes(:user).where(user_id: user.id).to_a
        end.not_to raise_error
      end
    end
  end

  describe ".preload_eventables" do
    let(:user) { create(:confirmed_user) }

    it "preloads eventable data for a collection of events", :aggregate_failures do
      game_purchase = create(:game_purchase, user: user)
      favorite_game = create(:favorite_game, user: user)
      relationship = create(:relationship, follower: user)

      events = Views::NewEvent.where(user_id: user.id).to_a
      result = Views::NewEvent.preload_eventables(events)

      # Should return the same events
      expect(result).to eq(events)

      # Each event should have a preloaded subclass
      result.each do |event|
        expect(event.instance_variable_get(:@_preloaded_subclass)).not_to be_nil
      end

      # Eventables should be accessible without additional queries
      add_event = result.find(&:add_to_library?)
      expect(add_event.eventable).to eq(game_purchase)

      fav_event = result.find(&:favorite_game?)
      expect(fav_event.eventable).to eq(favorite_game)

      follow_event = result.find(&:following?)
      expect(follow_event.eventable).to eq(relationship)
    end

    it "returns an empty array when given no events" do
      result = Views::NewEvent.preload_eventables([])
      expect(result).to eq([])
    end
  end

  describe 'GamePurchase Event Destructions' do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game) }
    let(:game_purchase_event) { create(:game_purchase_library_event, user: user, eventable: game_purchase) }

    it 'GamePurchase should not be deleted when Event is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.not_to change(GamePurchase, :count)
    end

    it 'User should not be deleted when Event is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.not_to change(User, :count)
    end

    it 'Game should not be deleted when Event is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.not_to change(Game, :count)
    end

    it 'Event should be deleted when GamePurchase is deleted' do
      game_purchase
      expect { game_purchase.destroy }.to change(Views::NewEvent, :count).by(-1)
    end

    it 'Event should be deleted when User is deleted' do
      game_purchase_event
      expect { user.destroy }.to change(Events::GamePurchaseEvent, :count).by(-1)
    end

    it 'Event should be deleted when Game is deleted' do
      game_purchase
      expect { game.destroy }.to change(Views::NewEvent, :count).by(-1)
    end
  end

  describe 'FavoriteGame Event Destructions' do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:favorite_game) { create(:favorite_game, user: user, game: game) }
    let(:favorite_game_event) { create(:favorite_game_event, user: user, eventable: favorite_game) }

    it 'FavoriteGame should not be deleted when Event is deleted' do
      favorite_game_event
      expect { favorite_game_event.destroy }.not_to change(FavoriteGame, :count)
    end

    it 'User should not be deleted when Event is deleted' do
      favorite_game_event
      expect { favorite_game_event.destroy }.not_to change(User, :count)
    end

    it 'Game should not be deleted when Event is deleted' do
      favorite_game_event
      expect { favorite_game_event.destroy }.not_to change(Game, :count)
    end

    it 'Event should be deleted when FavoriteGame is deleted' do
      favorite_game
      expect { favorite_game.destroy }.to change(Views::NewEvent, :count).by(-1)
    end

    it 'FavoriteGame Event should be deleted when Game is deleted' do
      favorite_game
      expect { game.destroy }.to change(Views::NewEvent, :count).by(-1)
    end

    it 'FavoriteGame Event should be deleted when User is deleted' do
      favorite_game
      expect { user.destroy }.to change(Events::FavoriteGameEvent, :count).by(-1)
    end
  end

  describe 'User Creation Event Destructions' do
    let!(:user) { create(:confirmed_user) }

    it 'Event should be deleted when User is deleted' do
      expect { user.destroy }.to change(Events::UserEvent, :count).by(-1)
    end
  end

  describe 'User Relationship Event Destructions' do
    let!(:user) { create(:confirmed_user) }
    let(:relationship_follower) { create(:relationship, follower: user) }
    let(:relationship_followed) { create(:relationship, followed: user) }

    it 'Event should be deleted when Following User is deleted' do
      relationship_follower
      expect { user.destroy }.to change(Events::RelationshipEvent, :count).by(-1)
    end

    it 'Event should be deleted when Followed User is deleted' do
      relationship_followed
      expect { user.destroy }.to change(Events::RelationshipEvent, :count).by(-1)
    end

    it 'Event should be deleted when Relationship is deleted' do
      relationship_followed
      expect { relationship_followed.destroy }.to change(Events::RelationshipEvent, :count).by(-1)
    end
  end
end
