require 'rails_helper'

RSpec.describe "Engines", type: :request do
  describe "GET /engines" do
    it "works! (now write some real specs)" do
      get engines_path
      expect(response).to have_http_status(200)
    end
  end
end
