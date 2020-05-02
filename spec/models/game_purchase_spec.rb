# typed: false
require 'rails_helper'

RSpec.describe GamePurchase, type: :model do
  subject(:game_purchase) { build(:game_purchase) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_purchase).to be_valid
    end

    it { should validate_length_of(:comments).is_at_most(2000) }

    it 'validates the uniqueness of the game purchase' do
      expect(game_purchase).to validate_uniqueness_of(:game_id)
        .scoped_to(:user_id)
        .with_message('is already in your library')
    end

    it 'validates the rating' do
      expect(game_purchase).to validate_numericality_of(:rating)
        .only_integer
        .allow_nil
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    end

    it 'validates the hours_played' do
      expect(game_purchase).to validate_numericality_of(:hours_played)
        .allow_nil
        .is_greater_than_or_equal_to(0)
    end

    it 'validates the replay_count' do
      expect(game_purchase).to validate_numericality_of(:replay_count)
        .is_greater_than_or_equal_to(0)
        .allow_nil
    end

    it 'validates the completion status enum' do
      expect(game_purchase).to define_enum_for(:completion_status)
        .with_values(
          [
            :unplayed,
            :in_progress,
            :dropped,
            :completed,
            :fully_completed,
            :not_applicable,
            :paused
          ]
        )
        .backed_by_column_of_type(:integer)
    end
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:user) }
    it { should have_many(:game_purchase_platforms) }
    it { should have_many(:platforms).through(:game_purchase_platforms).source(:platform) }
    it { should have_many(:game_purchase_stores) }
    it { should have_many(:stores).through(:game_purchase_stores).source(:store) }
    it { should have_many(:events).dependent(:destroy) }
  end

  describe 'Destructions' do
    let(:game) { create(:game) }
    let(:user) { create(:confirmed_user) }
    let(:game_purchase) { create(:game_purchase, user: user, game: game) }
    let(:game_purchase_platform) { create(:game_purchase_platform) }
    let(:game_purchase_with_platform) { create(:game_purchase, game_purchase_platforms: [game_purchase_platform]) }
    let(:game_purchase_store) { create(:game_purchase_store) }
    let(:game_purchase_with_store) { create(:game_purchase, game_purchase_stores: [game_purchase_store]) }

    it 'User should not be deleted when game purchase is deleted' do
      game_purchase
      expect { game_purchase.destroy }.to change(User, :count).by(0)
    end

    it 'Game should not be deleted when game purchase is deleted' do
      game_purchase
      expect { game_purchase.destroy }.to change(Game, :count).by(0)
    end

    it 'Platform should not be deleted when game purchase is deleted' do
      game_purchase_with_platform
      expect { game_purchase_with_platform.destroy }.to change(Platform, :count).by(0)
    end

    it 'GamePurchasePlatform should be deleted when game purchase is deleted' do
      game_purchase_with_platform
      expect { game_purchase_with_platform.destroy }.to change(GamePurchasePlatform, :count).by(-1)
    end

    it 'GamePurchaseStore should be deleted when game purchase is deleted' do
      game_purchase_with_store
      expect { game_purchase_with_store.destroy }.to change(GamePurchaseStore, :count).by(-1)
    end
  end

  describe 'Callbacks' do
    context 'with events' do
      let(:game) { create(:game) }
      let(:user) { create(:confirmed_user) }
      let(:game_purchase) { create(:game_purchase, user: user, game: game) }

      it 'Event should be created when GamePurchase is created' do
        user
        expect { game_purchase }.to change(Event, :count).by(1)
      end

      it 'Event should be created when GamePurchase is modified' do
        game_purchase
        expect do
          game_purchase.completion_status = :dropped
          game_purchase.save
        end.to change(Event.where(eventable_type: 'GamePurchase'), :count).by(1)
      end
    end

    context 'with game purchases' do
      let(:game) { create(:game) }
      let(:game_purchase1) { create(:game_purchase, game: game, rating: nil) }
      let(:game_purchase2) { create(:game_purchase, game: game, rating: 15) }
      let(:game_purchase3) { create(:game_purchase, game: game, rating: 5) }

      it 'Average rating should be updated when GamePurchase is created' do
        game_purchase1
        game_purchase2
        expect { game_purchase3 }.to change(game, :avg_rating).from(15).to(10)
      end

      it 'Average rating should be updated when GamePurchase is updated' do
        game_purchase2
        game_purchase3
        expect do
          game_purchase3.rating = 20
          game_purchase3.save
        end.to change(game, :avg_rating).from(10).to(17.5)
      end

      it 'Average rating should be updated when GamePurchase is deleted' do
        game_purchase2
        game_purchase3
        expect { game_purchase3.destroy }.to change(game, :avg_rating).from(10).to(15)
      end

      it 'Average rating should be updated when GamePurchase is deleted and no others exist' do
        game_purchase1
        game_purchase2
        expect { game_purchase2.destroy }.to change(game, :avg_rating).from(15).to(nil)
      end
    end
  end
end
