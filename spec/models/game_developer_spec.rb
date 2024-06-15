# typed: false
require 'rails_helper'

RSpec.describe GameDeveloper, type: :model do
  subject(:game_developer) { build(:game_developer) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(game_developer).to be_valid
    end

    it { should validate_uniqueness_of(:game_id).scoped_to(:company_id) }
  end

  describe "Associations" do
    it { should belong_to(:game) }
    it { should belong_to(:company) }
  end

  describe 'Destructions' do
    let(:developer) { create(:company) }
    let(:game) { create(:game) }
    let(:game_developer) { create(:game_developer, company: developer, game: game) }

    it 'Game should not be deleted when GameDeveloper is deleted' do
      game_developer
      expect { game_developer.destroy }.not_to change(Game, :count)
    end

    it 'Company should not be deleted when GameDeveloper is deleted' do
      game_developer
      expect { game_developer.destroy }.not_to change(Company, :count)
    end
  end
end
