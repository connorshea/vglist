# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL operation allowlist", type: :request do
  let(:stats_query) { OperationAllowlist.operations.fetch('GetBasicSiteStatistics') }

  def graphql(query, headers: {})
    post graphql_path, params: { query: query }.to_json, headers: { 'Content-Type' => 'application/json' }.merge(headers)
  end

  def jwt_headers(user)
    { 'Authorization' => "Bearer #{JwtService.encode(user)}" }
  end

  describe 'the manifest' do
    it 'lists the operations the SPA sends' do
      expect(OperationAllowlist.operations).to include('GetGame', 'GetGames', 'SignIn', 'GetUserLibrary')
    end

    it 'only contains operations that are valid against the current schema' do
      invalid = OperationAllowlist.operations.filter_map do |name, document|
        errors = VideoGameListSchema.validate(document)
        "#{name}: #{errors.map(&:message).join(', ')}" if errors.any?
      end

      expect(invalid).to be_empty
    end

    it 'only contains operations under the size limit' do
      too_large = OperationAllowlist.operations.select { |_name, document| document.bytesize > OperationAllowlist::MAX_QUERY_BYTES }

      expect(too_large.keys).to be_empty
    end
  end

  describe '.canonical' do
    it 'ignores whitespace and fragment order' do
      game = OperationAllowlist.operations.fetch('GetGame')
      fragment_first = game.split(/(?=^fragment )/).rotate.join("\n")

      expect(OperationAllowlist.canonical(fragment_first)).to eq(OperationAllowlist.canonical(game))
      expect(OperationAllowlist.canonical(game.squish)).to eq(OperationAllowlist.canonical(game))
    end

    it 'returns nil for an unparseable document' do
      expect(OperationAllowlist.canonical('query {')).to be_nil
    end

    it 'returns nil for a schema definition document' do
      expect(OperationAllowlist.canonical('schema { query: Query }')).to be_nil
    end
  end

  context 'when the allowlist is enforced' do
    before(:each) { allow(OperationAllowlist).to receive(:enabled?).and_return(true) }

    it 'runs an allowlisted operation' do
      graphql(stats_query)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('data', 'basicSiteStatistics')).to be_present
    end

    it 'runs an allowlisted operation formatted differently' do
      graphql(stats_query.squish)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('data', 'basicSiteStatistics')).to be_present
    end

    it 'rejects an operation the SPA does not send' do
      graphql('query { games { nodes { owners { nodes { gamePurchases { nodes { id } } } } } } }')

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['errors'].first['message']).to include('not allowed')
    end

    it 'rejects an allowlisted operation with an extra field' do
      graphql(stats_query.sub('games', "games\n    users"))

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects introspection' do
      graphql('{ __schema { types { name } } }')

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects an unparseable document' do
      graphql('query {')

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects a schema definition document' do
      graphql('schema { query: Query }')

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects an oversized document without parsing it' do
      allow(GraphQL).to receive(:parse).and_call_original
      # The allowlisted document plus a long comment, which wouldn't change it.
      padded = "#{stats_query}\n# #{'x' * OperationAllowlist::MAX_QUERY_BYTES}"

      graphql(padded)

      expect(response).to have_http_status(:bad_request)
      expect(GraphQL).not_to have_received(:parse)
    end

    it 'rejects ad-hoc operations from signed-in members' do
      graphql('{ currentUser { id } }', headers: jwt_headers(create(:confirmed_user)))

      expect(response).to have_http_status(:bad_request)
    end

    it 'lets admins send ad-hoc operations' do
      graphql('{ currentUser { id } }', headers: jwt_headers(create(:confirmed_admin)))

      expect(response).to have_http_status(:success)
      expect(response.parsed_body.dig('data', 'currentUser', 'id')).to be_present
    end
  end

  context 'when the allowlist is not enforced' do
    it 'runs ad-hoc operations' do
      graphql('{ __typename }')

      expect(response).to have_http_status(:success)
    end
  end
end
