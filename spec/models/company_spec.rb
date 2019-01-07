require 'rails_helper'

RSpec.describe Company, type: :model do
  subject(:company) { FactoryBot.create(:company) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(company).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end
end
