# typed: false
require 'rails_helper'

RSpec.describe "CreateStore Mutation API", type: :request do
  describe "Mutation creates a new store record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let(:query_string) do
      <<-GRAPHQL
        mutation($name: String!) {
          createStore(name: $name) {
            store {
              name
            }
          }
        }
      GRAPHQL
    end

    [:user, :moderator, :admin].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }

        it "increases the number of stores" do
          expect do
            api_request(query_string, variables: { name: 'Steam' }, token: access_token)
          end.to change(Store, :count).by(1)
        end

        it "returns basic data for store after creation" do
          result = api_request(query_string, variables: { name: 'Steam' }, token: access_token)

          expect(result.graphql_dig(:create_store, :store)).to eq(
            {
              name: 'Steam'
            }
          )
        end
      end
    end
  end
end
