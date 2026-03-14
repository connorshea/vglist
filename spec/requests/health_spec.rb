require 'rails_helper'

RSpec.describe "Health check", type: :request do
  describe "GET /health" do
    it "returns ok status" do
      get '/health'

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('ok')
    end
  end
end
