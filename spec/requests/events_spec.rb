# typed: false
require 'rails_helper'

RSpec.describe "Events", type: :request do
  describe "DELETE event_path" do
    let(:user) { create(:confirmed_user) }
    let!(:event) { create(:event, user: user) }

    it "deletes an event" do
      sign_in(user)
      expect do
        delete event_path(id: event.id)
      end.to change(Views::NewEvent, :count).by(-1)
    end
  end
end
