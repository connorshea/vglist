# typed: false
require 'rails_helper'

RSpec.describe "Activity", type: :request do
  describe "GET activity_path" do
    it "returns http success" do
      get activity_index_path
      expect(response).to have_http_status(:success)
    end
  end
end
