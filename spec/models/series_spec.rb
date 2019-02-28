require 'rails_helper'

RSpec.describe Series, type: :model do
  subject(:series) { FactoryBot.create(:series) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(series).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
  end

  describe "Associations" do
    it { should have_many(:games) }
  end
end
