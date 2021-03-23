# typed: false
require 'rails_helper'

RSpec.describe "UpdateSeries Mutation API", type: :request do
  describe "Mutation updates an existing series record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:series) { create(:series, name: 'Half-Life') }
    let(:query_string) do
      <<-GRAPHQL
        mutation($seriesId: ID!, $name: String, $wikidataId: ID) {
          updateSeries(seriesId: $seriesId, name: $name, wikidataId: $wikidataId) {
            series {
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

        it "does not change the number of series" do
          expect do
            api_request(query_string, variables: { series_id: series.id, name: 'Portal', wikidata_id: 123 }, token: access_token)
          end.not_to change(Series, :count)
        end

        it "returns basic data for series after creation" do
          result = api_request(query_string, variables: { series_id: series.id, name: 'Portal', wikidata_id: 123 }, token: access_token)

          expect(result.graphql_dig(:update_series, :series)).to eq(
            {
              name: 'Portal',
              wikidataId: 123
            }
          )

          expect(series.reload.name).to eq('Portal')
          expect(series.reload.wikidata_id).to eq(123)
        end
      end
    end
  end
end
