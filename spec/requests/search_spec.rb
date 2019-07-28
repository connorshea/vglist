# typed: false
require 'rails_helper'

RSpec.describe "Search", type: :request do
  describe "GET search_path" do
    let(:series) { create(:series) }

    it "returns the given series" do
      get search_path(query: series.name, format: :json)
      expected_response = { searchable_id: series.id, content: series.name, searchable_type: 'Series' }.stringify_keys
      expect(JSON.parse(response.body)['Series'].first).to include(expected_response)
    end

    it "returns no series" do
      get search_path(query: SecureRandom.alphanumeric(8), format: :json)
      expected_response = {}
      %w[Game Series Company Platform Engine Genre].each do |type|
        expected_response[type] = []
      end
      expect(response.body).to eq(expected_response.to_json)
    end

    it "returns no series when no query is given" do
      get search_path(format: :json)
      expected_response = {}
      %w[Game Series Company Platform Engine Genre].each do |type|
        expected_response[type] = []
      end
      expect(response.body).to eq(expected_response.to_json)
    end
  end
end
