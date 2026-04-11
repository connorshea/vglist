# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::FavoriteGameEvent, type: :model do
  subject(:favorite_game_event) { build(:favorite_game_event) }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(favorite_game_event).to be_valid
    end

    it { should validate_presence_of(:event_category) }
  end

  describe "Associations" do
    it { should belong_to(:eventable).class_name('FavoriteGame') }
    it { should belong_to(:user) }
  end

  describe "Enums" do
    it {
      should define_enum_for(:event_category).with_values(
        favorite_game: 2
      )
    }
  end
end
