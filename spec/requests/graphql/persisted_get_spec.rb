# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GraphQL GET requests with persisted documents", type: :request do
  let(:operations) { OperationAllowlist.operations }
  let(:user) { create(:confirmed_user) }
  let!(:game) { create(:game, name: 'Before') }

  let(:shelf_variables) do
    {
      first: 6,
      after: nil,
      sortBy: 'NEWEST',
      onPlatform: nil,
      byGenre: nil,
      byEngine: nil,
      fromYear: nil,
      toYear: nil,
      excludeLibrary: nil,
      withCount: false
    }
  end

  # The test environment uses a null store.
  around(:each) do |example|
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original
  end

  def document_id(operation_name)
    "sha256:#{Digest::SHA256.hexdigest(operations.fetch(operation_name))}"
  end

  def graphql_get(operation_name, variables: nil, id: document_id(operation_name), headers: {}, **extra)
    params = { operationName: operation_name, documentId: id, **extra }
    params[:variables] = variables.to_json unless variables.nil?
    get graphql_path, params: params, headers: headers
    JSON.parse(response.body)
  end

  it "runs a persisted query" do
    body = graphql_get('GetGamesIndex', variables: shelf_variables)
    expect(response).to have_http_status(:ok)
    expect(body.dig('data', 'games', 'nodes').pluck('name')).to eq(['Before'])
  end

  it "lets Cloudflare cache a cacheable signed-out response", :aggregate_failures do
    graphql_get('GetGamesIndex', variables: shelf_variables)
    expect(response.headers['Cache-Control']).to eq('max-age=60, public, stale-while-revalidate=600, s-maxage=300')
    expect(response.headers['Access-Control-Allow-Origin']).to eq('http://localhost:5173')

    # Served from PublicResponseCache, still with the same headers.
    graphql_get('GetGamesIndex', variables: shelf_variables)
    expect(response.headers['Cache-Control']).to eq('max-age=60, public, stale-while-revalidate=600, s-maxage=300')
  end

  it "answers HEAD like GET, so `curl -I` shows the cache headers", :aggregate_failures do
    head graphql_path, params: { operationName: 'GetHeroCovers', documentId: document_id('GetHeroCovers') }
    expect(response).to have_http_status(:ok)
    expect(response.headers['Cache-Control']).to eq('max-age=60, public, stale-while-revalidate=600, s-maxage=300')
  end

  it "doesn't let anything cache an uncacheable query" do
    graphql_get('GetGamesIndex', variables: shelf_variables.merge(fromYear: 2000))
    expect(response).to have_http_status(:ok)
    expect(response.headers['Cache-Control']).to eq('no-store')
  end

  it "doesn't let anything cache errors" do
    allow(VideoGameListSchema).to receive(:execute).and_return({ 'data' => nil, 'errors' => [{ 'message' => 'Timeout' }] })
    graphql_get('GetHeroCovers')
    expect(response.headers['Cache-Control']).to eq('no-store')
  end

  it "rejects requests with an Authorization header", :aggregate_failures do
    graphql_get('GetHeroCovers', headers: { 'Authorization' => "Bearer #{JwtService.encode(user)}" })
    expect(response).to have_http_status(:bad_request)
    expect(response.headers['Cache-Control']).to eq('no-store')
  end

  it "rejects a query document sent over GET" do
    graphql_get('GetHeroCovers', id: nil, query: operations['GetHeroCovers'])
    expect(response).to have_http_status(:bad_request)
  end

  it "answers 404 for an unknown document ID, so the SPA falls back to POST", :aggregate_failures do
    body = graphql_get('GetHeroCovers', id: "sha256:#{'0' * 64}")
    expect(response).to have_http_status(:not_found)
    expect(body.dig('errors', 0, 'extensions', 'code')).to eq('PERSISTED_DOCUMENT_NOT_FOUND')
    expect(response.headers['Cache-Control']).to eq('no-store')
  end

  it "answers 404 when the operation name doesn't match the document" do
    graphql_get('GetGamesIndex', id: document_id('GetHeroCovers'))
    expect(response).to have_http_status(:not_found)
  end

  it "rejects mutations with 405", :aggregate_failures do
    expect do
      graphql_get('DeleteGame', variables: { id: game.id.to_s })
    end.not_to change(Game, :count)
    expect(response).to have_http_status(:method_not_allowed)
    expect(response.headers['Allow']).to eq('POST')
  end

  it "gives the SPA persisted document IDs for exactly the operations PublicResponseCache can cache" do
    generated = Rails.root.join('frontend/src/types/persisted-documents.ts').read
    ids = generated.scan(/(\w+): "(sha256:\h{64})"/).to_h
    expect(ids).to eq(PublicResponseCache::OPERATIONS.index_with { |name| document_id(name) })
  end

  it "never lets a POST response be cached, even a cacheable one" do
    post graphql_path, params: { query: operations['GetHeroCovers'], operationName: 'GetHeroCovers' }
    expect(response.headers['Cache-Control']).to eq('no-store')
  end
end
