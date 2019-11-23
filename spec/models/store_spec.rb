# typed: false
require 'rails_helper'

RSpec.describe Store, type: :model do
  subject(:store) { build(:store) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(store).to be_valid
    end

    it { should validate_presence_of(:name) }

    it { should validate_length_of(:name).is_at_most(120) }
  end
end
