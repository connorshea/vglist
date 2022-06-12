# typed: false
require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(user).to be_valid
    end

    # Validate length of username.
    it do
      expect(user).to validate_length_of(:username)
        .is_at_least(3).is_at_most(20)
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

    it 'has a privacy enum with private_account or public_account' do
      expect(user).to define_enum_for(:privacy)
        .with_values([:public_account, :private_account])
    end

    it 'has a default role of member' do
      expect(user.role).to eql("member")
    end

    it 'has a default privacy of public_account' do
      expect(user.privacy).to eql("public_account")
    end

    it { should validate_presence_of(:role) }

    it 'has an optional avatar' do
      expect(user).not_to validate_attached_of(:avatar)
      expect(user).to validate_content_type_of(:avatar).allowing('image/png', 'image/jpg', 'image/jpeg')
      expect(user).to validate_size_of(:avatar).less_than(3.megabytes)
    end
  end

  describe 'Custom Validations' do
    let(:user) { build(:user, username: 'system') }

    it 'fails validation if username is reserved' do
      user
      expect(user).to be_invalid
      expect(user.errors[:username]).to include('is reserved by the system')
    end
  end

  describe "Associations" do
    it { should have_many(:game_purchases) }
    it { should have_many(:games).through(:game_purchases) }
    it { should have_many(:favorite_games).dependent(:destroy) }
    it { should have_many(:favorited_games).through(:favorite_games) }

    it { should have_many(:new_events) }
    it { should have_many(:game_purchase_events).dependent(:destroy) }
    it { should have_many(:relationship_events).dependent(:destroy) }
    it { should have_many(:user_events).dependent(:destroy) }
    it { should have_many(:favorite_game_events).dependent(:destroy) }

    it { should have_many(:wikidata_blocklists).dependent(:nullify) }
    it { should have_many(:steam_blocklists).dependent(:nullify) }
    it { should have_one(:external_account).dependent(:destroy) }

    it 'have many access grants' do
      expect(user).to have_many(:access_grants)
        .class_name('Doorkeeper::AccessGrant')
        .with_foreign_key(:resource_owner_id)
        .dependent(:destroy)
    end

    it 'have many access tokens' do
      expect(user).to have_many(:access_tokens)
        .class_name('Doorkeeper::AccessToken')
        .with_foreign_key(:resource_owner_id)
        .dependent(:destroy)
    end

    it 'has many active relationships' do
      expect(user).to have_many(:active_relationships)
        .class_name('Relationship')
        .with_foreign_key('follower_id')
        .inverse_of(:follower)
        .dependent(:destroy)

      expect(user).to have_many(:following)
        .through(:active_relationships)
        .source(:followed)
    end

    it 'has many passive relationships' do
      expect(user).to have_many(:passive_relationships)
        .class_name('Relationship')
        .with_foreign_key('followed_id')
        .inverse_of(:followed)
        .dependent(:destroy)

      expect(user).to have_many(:followers)
        .through(:passive_relationships)
        .source(:follower)
    end
  end

  describe 'Scopes' do
    context 'with most followers' do
      let(:user2) { create(:user, id: 1) }
      let(:user1) { create(:user) }

      it "returns users with most followers first" do
        expect(User.most_followers).to eq([user2, user1])
      end
    end

    context 'with most games' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }
      # rubocop:disable RSpec/LetSetup
      let!(:game_purchases1) { create_list(:game_purchase, 5, user_id: user1.id) }
      let!(:game_purchases2) { create_list(:game_purchase, 2, user_id: user2.id) }
      let!(:game_purchases3) { create_list(:game_purchase, 4, user_id: user3.id) }
      # rubocop:enable RSpec/LetSetup

      it "returns users with most games first" do
        expect(User.most_games).to eq([user1, user3, user2])
      end
    end
  end

  describe 'Destructions' do
    let(:user_with_favorite_game) { create(:user_with_favorite_game) }
    let(:user_with_game_purchase) { create(:user_with_game_purchase) }
    let(:user_with_external_account) { create(:user, :external_account) }

    it 'FavoriteGame should be deleted when owner is deleted' do
      user_with_favorite_game
      expect { user_with_favorite_game.destroy }.to change(FavoriteGame, :count).by(-1)
    end

    it 'GamePurchase should be deleted when owner is deleted' do
      user_with_game_purchase
      expect { user_with_game_purchase.destroy }.to change(GamePurchase, :count).by(-1)
    end

    it 'ExternalAccount should be deleted when owner is deleted' do
      user_with_external_account
      expect { user_with_external_account.destroy }.to change(ExternalAccount, :count).by(-1)
    end
  end

  describe 'Callbacks' do
    let(:user) { create(:confirmed_user, id: 1) }
    let(:user2) { create(:confirmed_user) }

    it 'User 1 should not follow themselves' do
      user
      # Get the first relationship the user has and make sure it's following the user with ID 1
      expect(user.active_relationships.length).to eq(0)
    end

    it 'User should follow user with ID 1' do
      user
      user2
      # Get the first relationship the user has and make sure it's following the user with ID 1
      expect(user2.active_relationships.first.followed_id).to eq(1)
    end
  end
end
