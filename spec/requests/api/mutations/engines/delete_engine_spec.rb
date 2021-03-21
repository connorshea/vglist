# typed: false
require 'rails_helper'

RSpec.describe "DeleteEngine Mutation API", type: :request do
  describe "Mutation deletes an existing engine record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:engine) { create(:engine) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($engineId: ID!) {
          deleteEngine(engineId: $engineId) {
            deleted
          }
        }
      GRAPHQL
    end

    context "when the current user is an admin" do
      let(:user) { create(:confirmed_admin) }

      it "decreases the number of engines" do
        expect do
          api_request(query_string, variables: { engine_id: engine.id }, token: access_token)
        end.to change(Engine, :count).by(-1)
      end

      it "returns true after deletion" do
        result = api_request(query_string, variables: { engine_id: engine.id }, token: access_token)

        expect(result.graphql_dig(:delete_engine, :deleted)).to eq(true)
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }

      it "does not change the number of engines" do
        expect do
          result = api_request(query_string, variables: { engine_id: engine.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to delete this engine.")
        end.not_to change(Engine, :count)
      end
    end
  end
end
