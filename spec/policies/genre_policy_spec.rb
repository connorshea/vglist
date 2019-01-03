require 'rails_helper'

RSpec.describe GenrePolicy do
  subject(:genre_policy) { described_class.new(user, genre) }

  describe 'A logged-in user' do
    let(:user) { create(:user) }
    let(:genre) { create(:genre) }

    it do
      expect(genre_policy).to permit_actions(
        [:index, :show, :create, :new, :edit, :update, :destroy]
      )
    end
  end

  describe 'A user that is not logged in' do
    let(:user) { nil }
    let(:genre) { create(:genre) }

    it { should permit_actions([:index, :show]) }
    it { should_not permit_actions([:create, :new, :edit, :update, :destroy]) }
  end
end
