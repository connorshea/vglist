# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "OpenSearch description", type: :request do
  describe "GET /opensearch" do
    it "returns the OpenSearch XML document", :aggregate_failures do
      get '/opensearch'

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('application/xml')
      expect(response.body).to include('<OpenSearchDescription')
      expect(response.body).to include('<ShortName>vglist</ShortName>')
      expect(response.body).to include('/search?query={searchTerms}')
    end
  end
end
