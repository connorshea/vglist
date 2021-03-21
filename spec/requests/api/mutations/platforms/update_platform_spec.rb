# typed: false
require 'rails_helper'

RSpec.describe "UpdatePlatform Mutation API", type: :request do
  describe "Mutation updates an existing platform record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:platform) { create(:platform, name: 'Xbox 360') }
    let(:query_string) do
      <<-GRAPHQL
        mutation($platformId: ID!, $name: String, $wikidataId: Int) {
          updatePlatform(platformId: $platformId, name: $name, wikidataId: $wikidataId) {
            platform {
              name
              wikidataId
            }
          }
        }
      GRAPHQL
    end

    [:moderator, :admin].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }

        it "does not change the number of platforms" do
          expect do
            api_request(query_string, variables: { platform_id: platform.id, name: 'Nintendo Switch', wikidata_id: 123 }, token: access_token)
          end.not_to change(Platform, :count)
        end

        it "returns basic data for platform after creation" do
          result = api_request(query_string, variables: { platform_id: platform.id, name: 'Nintendo Switch', wikidata_id: 123 }, token: access_token)

          expect(result.graphql_dig(:update_platform, :platform)).to eq(
            {
              name: 'Nintendo Switch',
              wikidataId: 123
            }
          )

          expect(platform.reload.name).to eq('Nintendo Switch')
          expect(platform.reload.wikidata_id).to eq(123)
        end
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }

      it "does not update the platform" do
        expect do
          result = api_request(query_string, variables: { platform_id: platform.id, name: 'Nintendo Switch', wikidata_id: 123 }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to update this platform.")
        end.not_to change(platform.reload, :name).from('Xbox 360')
      end
    end
  end
end
