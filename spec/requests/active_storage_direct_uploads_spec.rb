# frozen_string_literal: true

require 'rails_helper'

# ActiveStorage's DirectUploadsController has no authentication and returns a
# presigned upload URL for the public bucket, so the route is shadowed in
# config/routes.rb.
RSpec.describe "ActiveStorage direct uploads", type: :request do
  let(:blob_params) do
    { blob: { filename: 'cover.png', byte_size: 100, checksum: Digest::MD5.base64digest('x' * 100), content_type: 'image/png' } }
  end

  it "is not routable" do
    expect do
      post '/rails/active_storage/direct_uploads', params: blob_params, as: :json
    end.not_to change(ActiveStorage::Blob, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "is not routable with a format suffix" do
    post '/rails/active_storage/direct_uploads.json', params: blob_params, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
