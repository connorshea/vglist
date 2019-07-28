# typed: false
require 'rails_helper'

RSpec.describe GenrePolicy, type: :policy do
  subject(:genre_policy) { described_class.new(user, genre) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:genre) { create(:genre) }

    it "let's a normal user list, show, and search genres" do
      expect(genre_policy).to permit_actions(
        [:index, :show, :search]
      )
    end

    it "doesn't let a normal user create, update, or destroy genres" do
      expect(genre_policy).not_to permit_actions(
        [:create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A moderator user' do
    let(:user) { create(:moderator) }
    let(:genre) { create(:genre) }

    it "let's a moderator do everything" do
      expect(genre_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'An admin user' do
    let(:user) { create(:admin) }
    let(:genre) { create(:genre) }

    it "let's an admin do everything" do
      expect(genre_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy, :search]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:genre) { create(:genre) }

    it { should permit_actions([:index, :show]) }
    it { should_not permit_actions([:create, :new, :edit, :update, :destroy, :search]) }
  end
end
