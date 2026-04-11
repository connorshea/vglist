# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::UserEvent, type: :model do
  subject(:user_event) { build(:new_user_event) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(user_event).to be_valid
    end

    it { should validate_presence_of(:event_category) }
  end

  describe "Associations" do
    it { should belong_to(:eventable).class_name('User') }
    it { should belong_to(:user) }
  end

  describe "Enums" do
    it {
      should define_enum_for(:event_category).with_values(
        new_user: 3
      )
    }
  end
end
