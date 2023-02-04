# typed: false
require 'rails_helper'

# rubocop:disable RSpec/FilePath
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

  describe 'GamePurchase Event Destructions' do
    let(:user) { create(:confirmed_user) }
    let(:game) { create(:game) }
    let(:game_purchase) { create(:game_purchase, game: game) }
    let(:game_purchase_event) { create(:game_purchase_library_event, user: user, eventable: game_purchase) }

    it 'GamePurchase should not be deleted when Event is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.to change(GamePurchase, :count).by(0)
    end

    it 'User should not be deleted when Event is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.to change(User, :count).by(0)
    end

    it 'Game should not be deleted when Event is deleted' do
      game_purchase_event
      expect { game_purchase_event.destroy }.to change(Game, :count).by(0)
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
      expect { favorite_game_event.destroy }.to change(FavoriteGame, :count).by(0)
    end

    it 'User should not be deleted when Event is deleted' do
      favorite_game_event
      expect { favorite_game_event.destroy }.to change(User, :count).by(0)
    end

    it 'Game should not be deleted when Event is deleted' do
      favorite_game_event
      expect { favorite_game_event.destroy }.to change(Game, :count).by(0)
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
# rubocop:enable RSpec/FilePath
