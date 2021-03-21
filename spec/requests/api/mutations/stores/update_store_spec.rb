# typed: false
require 'rails_helper'

RSpec.describe "UpdateStore Mutation API", type: :request do
  describe "Mutation updates an existing store record" do
    let(:application) { build(:application, owner: user) }
    let(:access_token) { create(:access_token, resource_owner_id: user.id, application: application) }
    let!(:store) { create(:store, name: 'Origin') }
    let(:query_string) do
      <<-GRAPHQL
        mutation($storeId: ID!, $name: String) {
          updateStore(storeId: $storeId, name: $name) {
            store {
              name
            }
          }
        }
      GRAPHQL
    end

    [:moderator, :admin].each do |role|
      context "when the current user is a(n) #{role}" do
        let(:user) { create("confirmed_#{role}".to_sym) }

        it "does not change the number of stores" do
          expect do
            api_request(query_string, variables: { store_id: store.id, name: 'Nintendo eShop' }, token: access_token)
          end.not_to change(Store, :count)
        end

        it "returns basic data for store after creation" do
          result = api_request(query_string, variables: { store_id: store.id, name: 'Nintendo eShop' }, token: access_token)

          expect(result.graphql_dig(:update_store, :store)).to eq(
            {
              name: 'Nintendo eShop'
            }
          )

          expect(store.reload.name).to eq('Nintendo eShop')
        end
      end
    end

    context 'when the current user is a normal member' do
      let(:user) { create(:confirmed_user) }

      it "does not update the store" do
        expect do
          result = api_request(query_string, variables: { store_id: store.id, name: 'Nintendo eShop' }, token: access_token)
          expect(result.to_h['errors'].first['message']).to eq("You aren't allowed to update this store.")
        end.not_to change(store.reload, :name).from('Origin')
      end
    end
  end
end
