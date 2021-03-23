# typed: false
require 'rails_helper'

RSpec.describe "CreateGenre Mutation API", type: :request do
  describe "Mutation creates a new genre record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($name: String!, $wikidataId: ID!) {
          createGenre(name: $name, wikidataId: $wikidataId) {
            genre {
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

        it "increases the number of genres" do
          expect do
            api_request(query_string, variables: { name: 'First-person shooter', wikidata_id: 123 }, token: access_token)
          end.to change(Genre, :count).by(1)
        end

        it "returns basic data for genre after creation" do
          result = api_request(query_string, variables: { name: 'First-person shooter', wikidata_id: 123 }, token: access_token)

          expect(result.graphql_dig(:create_genre, :genre)).to eq(
            {
              name: 'First-person shooter',
              wikidataId: 123
            }
          )
        end
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }

      it "does not create a new genre" do
        expect do
          result = api_request(query_string, variables: { name: 'First-person shooter', wikidata_id: 123 }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to create a genre.")
        end.not_to change(Genre, :count)
      end
    end
  end
end
