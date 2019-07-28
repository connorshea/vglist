# typed: false
require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET about_path" do
    it "returns http success" do
      get about_path
      expect(response).to have_http_status(:success)
    end
  end
end
