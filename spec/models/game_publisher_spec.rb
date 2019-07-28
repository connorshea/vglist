# typed: false
require 'rails_helper'

RSpec.describe GamePublisher, type: :model do
  subject(:game_publisher) { FactoryBot.create(:game_publisher) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_publisher).to be_valid
    end

    it { should validate_uniqueness_of(:game_id).scoped_to(:company_id) }
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:company) }
  end

  describe 'Destructions' do
    let(:publisher) { create(:company) }
    let(:game) { create(:game) }
    let(:game_publisher) { create(:game_publisher, company: publisher, game: game) }

    it 'Game should not be deleted when GamePublisher is deleted' do
      game_publisher
      expect { game_publisher.destroy }.to change(Game, :count).by(0)
    end

    it 'Company should not be deleted when GamePublisher is deleted' do
      game_publisher
      expect { game_publisher.destroy }.to change(Company, :count).by(0)
    end
  end
end
