# typed: false
require 'rails_helper'

RSpec.describe "UpdateGenre Mutation API", type: :request do
  describe "Mutation updates an existing genre record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:genre) { create(:genre, name: 'First-person shooter') }
    let(:query_string) do
      <<-GRAPHQL
        mutation($genreId: ID!, $name: String, $wikidataId: Int) {
          updateGenre(genreId: $genreId, name: $name, wikidataId: $wikidataId) {
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

        it "does not change the number of genres" do
          expect do
            api_request(query_string, variables: { genre_id: genre.id, name: 'Third-person shooter', wikidata_id: 123 }, token: access_token)
          end.not_to change(Genre, :count)
        end

        it "returns basic data for genre after creation" do
          result = api_request(query_string, variables: { genre_id: genre.id, name: 'Third-person shooter', wikidata_id: 123 }, token: access_token)

          expect(result.graphql_dig(:update_genre, :genre)).to eq(
            {
              name: 'Third-person shooter',
              wikidataId: 123
            }
          )

          expect(genre.reload.name).to eq('Third-person shooter')
          expect(genre.reload.wikidata_id).to eq(123)
        end
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }

      it "does not update the genre" do
        expect do
          result = api_request(query_string, variables: { genre_id: genre.id, name: 'Third-person shooter', wikidata_id: 123 }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to update this genre.")
        end.not_to change(genre.reload, :name).from('First-person shooter')
      end
    end
  end
end
