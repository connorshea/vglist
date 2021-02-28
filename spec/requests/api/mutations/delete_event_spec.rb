# typed: false
require 'rails_helper'

RSpec.describe "DeleteEvent Mutation API", type: :request do
  describe "Mutation deletes event" do
    let!(:user) { create(:confirmed_user) }
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:user2) { create(:confirmed_user) }
    let(:event) { create(:event, user: user) }
    let(:other_event) { create(:event, user: user2) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($id: ID!) {
          deleteEvent(eventId: $id) {
            deleted
          }
        }
      GRAPHQL
    end

    it "deletes an event" do
      event

      expect do
        api_request(query_string, variables: { id: event.id }, token: access_token)
      end.to change(Event, :count).by(-1)
    end

    it "does not delete an event we do not own" do
      other_event

      expect do
        result = api_request(query_string, variables: { id: other_event.id }, token: access_token)
        expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to delete this event.")
      end.to change(Event, :count).by(0)
    end

    it "returns a deleted boolean after deleting the event" do
      event

      result = api_request(query_string, variables: { id: event.id }, token: access_token)

      expect(result.graphql_dig(:delete_event, :deleted)).to eq(true)
    end
  end
end
