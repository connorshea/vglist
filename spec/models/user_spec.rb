require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { FactoryBot.create(:user) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    # Validate length of username.
    it do
      expect(user).to validate_length_of(:username)
        .is_at_least(4).is_at_most(20)
    end

    # Usernames should be unique.
    it { should validate_uniqueness_of(:username) }

    # Make sure a bunch of normal usernames work fine
    it 'allows valid usernames' do
      expect(user).to allow_values(
        "janedoe",
        "john_doe",
        "jane.doe",
        "janedoe400",
        "JohnDoe"
      ).for(:username)
    end

    # Disallow weird uses of underscores and periods
    it 'disallows invalid usernames' do
      expect(user).not_to allow_values(
        "double__underscore",
        "_underscore",
        "underscore_",
        "double..period",
        "period.",
        ".period"
      ).for(:username)
    end

    # Validate uniqueness of email
    it do
      expect(user).to validate_uniqueness_of(:email)
        .ignoring_case_sensitivity
        .with_message("has already been taken")
    end

    # Validate bio length limit
    it { should validate_length_of(:bio).is_at_most(1000) }

    it 'has a role with possible values of member, moderator, and admin' do
      expect(user).to define_enum_for(:role)
        .with_values([:member, :moderator, :admin])
    end

    it 'has a default role of member' do
      expect(user.role).to eql("member")
    end

    it { should validate_presence_of(:role) }
  end

  describe "Associations" do
    it { should have_many(:game_purchases) }
    it { should have_many(:games).through(:game_purchases) }
    it { should have_many(:favorites).inverse_of(:user).dependent(:destroy) }
    it { should have_one(:external_account).dependent(:destroy) }
  end

  describe 'Destructions' do
    let(:user_with_favorite) { create(:user_with_favorite) }
    let(:user_with_game_purchase) { create(:user_with_game_purchase) }

    it 'Favorite should be deleted when owner is deleted' do
      user_with_favorite
      expect { user_with_favorite.destroy }.to change(Favorite, :count).by(-1)
    end

    it 'GamePurchase should be deleted when owner is deleted' do
      user_with_game_purchase
      expect { user_with_game_purchase.destroy }.to change(GamePurchase, :count).by(-1)
    end
  end
end
