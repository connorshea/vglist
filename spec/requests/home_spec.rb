require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET root_path" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
