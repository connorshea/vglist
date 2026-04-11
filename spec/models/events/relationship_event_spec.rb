# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::RelationshipEvent, type: :model do
  subject(:relationship_event) { build(:following_event) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(relationship_event).to be_valid
    end

    it { should validate_presence_of(:event_category) }
  end

  describe "Associations" do
    it { should belong_to(:eventable).class_name('Relationship') }
    it { should belong_to(:user) }
  end

  describe "Enums" do
    it {
      should define_enum_for(:event_category).with_values(
        following: 4
      )
    }
  end
end
