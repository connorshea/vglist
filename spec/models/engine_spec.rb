require 'rails_helper'

RSpec.describe Engine, type: :model do
  subject(:engine) { FactoryBot.create(:engine) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(engine).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
  end
end
