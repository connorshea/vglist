require 'rails_helper'

RSpec.describe UnmatchedGame, type: :model do
  subject(:unmatched_game) { build(:unmatched_game) }

  describe "Associations" do
    it { should belong_to(:user).optional }
  end
end
