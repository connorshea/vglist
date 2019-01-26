require 'rails_helper'

RSpec.describe ReleasesHelper, type: :helper do
  describe 'release in user library' do
    let(:release) { create(:release) }
    let(:user) { create(:confirmed_user) }
    let(:user_with_release) { create(:confirmed_user) }
    let(:release_purchase) { create(:release_purchase, user: user_with_release, release: release) }

    it 'returns true when release is in user library' do
      allow(controller).to receive(:current_user).and_return(user_with_release)
      release_purchase
      expect(helper.release_in_user_library?(release)).to be(true)
    end

    it 'returns false when release is not in user library' do
      allow(controller).to receive(:current_user).and_return(user)
      expect(helper.release_in_user_library?(release)).to be(false)
    end
  end
end
