# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Avatar upload", type: :request do
  let(:path) { '/api/users/me/avatar' }
  let(:square_image) { Rack::Test::UploadedFile.new(Rails.root.join('spec/factories/images/avatar.jpg'), 'image/jpeg') }
  let(:portrait_image) { Rack::Test::UploadedFile.new(Rails.root.join('spec/factories/images/crysis.jpg'), 'image/jpeg') }

  def auth_headers(user)
    { 'Authorization' => "Bearer #{JwtService.encode(user)}" }
  end

  context 'when signed in' do
    let(:user) { create(:confirmed_user) }

    it 'attaches the avatar and returns its URL', :aggregate_failures do
      post path, params: { avatar: square_image }, headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      expect(user.reload.avatar).to be_attached
      expect(response.parsed_body['avatar_url']).to be_present
    end

    it 'replaces an existing avatar' do
      user = create(:confirmed_user_with_avatar)
      old_blob_id = user.avatar.blob.id

      post path, params: { avatar: square_image }, headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      expect(user.reload.avatar.blob.id).not_to eq(old_blob_id)
    end

    it 'rejects an image that is not square', :aggregate_failures do
      post path, params: { avatar: portrait_image }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).to be_present
      expect(user.reload.avatar).not_to be_attached
    end

    it 'rejects a file that is not an image', :aggregate_failures do
      text_file = Rack::Test::UploadedFile.new(StringIO.new('not an image'), 'image/png', original_filename: 'avatar.png')

      post path, params: { avatar: text_file }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.avatar).not_to be_attached
    end

    it 'rejects a request without a file', :aggregate_failures do
      post path, params: { avatar: 'not a file' }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).to eq(['No avatar image was uploaded.'])
    end
  end

  context 'when signed in as a banned user' do
    let(:user) { create(:banned_user) }

    it 'is forbidden', :aggregate_failures do
      post path, params: { avatar: square_image }, headers: auth_headers(user)

      expect(response).to have_http_status(:forbidden)
      expect(user.reload.avatar).not_to be_attached
    end
  end

  context 'when not signed in' do
    it 'is unauthorized' do
      expect do
        post path, params: { avatar: square_image }
      end.not_to change(ActiveStorage::Attachment, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
