# typed: false
require 'rails_helper'

RSpec.describe "UpdateEngine Mutation API", type: :request do
  describe "Mutation updates an existing engine record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:engine) { create(:engine) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($engineId: ID!, $name: String, $wikidataId: ID) {
          updateEngine(engineId: $engineId, name: $name, wikidataId: $wikidataId) {
            engine {
              name
              wikidataId
            }
          }
        }
      GRAPHQL
    end

    [:user, :moderator, :admin].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }

        it "does not change the number of engines" do
          expect do
            api_request(query_string, variables: { engine_id: engine.id, name: 'GoldSrc', wikidata_id: 123 }, token: access_token)
          end.not_to change(Engine, :count)
        end

        it "returns basic data for engine after creation" do
          result = api_request(query_string, variables: { engine_id: engine.id, name: 'GoldSrc', wikidata_id: 123 }, token: access_token)

          expect(result.graphql_dig(:update_engine, :engine)).to eq(
            {
              name: 'GoldSrc',
              wikidataId: 123
            }
          )

          expect(engine.reload.name).to eq('GoldSrc')
          expect(engine.reload.wikidata_id).to eq(123)
        end
      end
    end
  end
end
