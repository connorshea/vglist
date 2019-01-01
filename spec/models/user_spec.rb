require 'rails_helper'

RSpec.describe User, type: :model do
  subject { FactoryBot.create(:user) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    # Validate length of username.
    it do
      should validate_length_of(:username)
        .is_at_least(4).is_at_most(20)
        .on(:create)
    end

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

    # Validate uniqueness of email and username
    it do
      should validate_uniqueness_of(:email)
        .ignoring_case_sensitivity
        .with_message("has already been taken")
        .on(:create)
    end

    it { should validate_uniqueness_of(:username).on(:create) }

    # Validate bio length limit
    it { should validate_length_of(:bio).is_at_most(1000).on(:create) }
  end

  describe "Associations" do
    it { should have_many(:release_purchases) }
    it { should have_many(:releases) }
  end
end
