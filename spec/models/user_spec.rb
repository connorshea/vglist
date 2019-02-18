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
    it { should allow_value("janedoe").for(:username) }
    it { should allow_value("john_doe").for(:username) }
    it { should allow_value("jane.doe").for(:username) }
    it { should allow_value("janedoe400").for(:username) }
    it { should allow_value("JohnDoe").for(:username) }

    # Disallow weird uses of underscores and periods
    it { should_not allow_value("double__underscore").for(:username) }
    it { should_not allow_value("_underscore").for(:username) }
    it { should_not allow_value("underscore_").for(:username) }
    it { should_not allow_value("double..period").for(:username) }
    it { should_not allow_value("period.").for(:username) }
    it { should_not allow_value(".period").for(:username) }

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
    it { should have_many(:games) }
  end
end
