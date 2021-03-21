# typed: false
require 'rails_helper'

RSpec.describe "DeleteSeries Mutation API", type: :request do
  describe "Mutation deletes an existing series record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:series) { create(:series) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($seriesId: ID!) {
          deleteSeries(seriesId: $seriesId) {
            deleted
          }
        }
      GRAPHQL
    end

    context "when the current user is an admin" do
      let(:user) { create(:confirmed_admin) }

      it "decreases the number of series" do
        expect do
          api_request(query_string, variables: { series_id: series.id }, token: access_token)
        end.to change(Series, :count).by(-1)
      end

      it "returns true after deletion" do
        result = api_request(query_string, variables: { series_id: series.id }, token: access_token)

        expect(result.graphql_dig(:delete_series, :deleted)).to eq(true)
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }

      it "does not change the number of series" do
        expect do
          result = api_request(query_string, variables: { series_id: series.id }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to delete this series.")
        end.not_to change(Series, :count)
      end
    end
  end
end
